import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:party_tricks/models/room.dart';
import 'package:party_tricks/screens/board_screen.dart';
import 'package:party_tricks/services/auth/auth_providers.dart';
import 'package:party_tricks/services/game/game_providers.dart';
import 'package:party_tricks/services/game/game_service.dart';
import 'package:party_tricks/services/game_engine/game_action.dart';
import 'package:party_tricks/services/game_engine/game_state.dart';
import 'package:party_tricks/services/game_engine/minigames.dart';
import 'package:party_tricks/services/rooms/room_providers.dart';
import 'package:party_tricks/widgets/active_game_banner.dart';

import '../services/rooms/fake_room_services.dart';

class _FakeGameService implements GameService {
  final controller = StreamController<GameState?>.broadcast();
  GameState? last;
  int hosting = 0;
  final sent = <GameAction>[];

  void emit(GameState state) {
    last = state;
    controller.add(state);
  }

  @override
  Stream<GameState?> watchGame(String roomId) async* {
    if (last != null) yield last;
    yield* controller.stream;
  }

  @override
  void Function() runHost(String roomId) {
    hosting++;
    return () => hosting--;
  }

  @override
  Future<void> sendAction(String roomId, GameAction action) async =>
      sent.add(action);

  @override
  Future<void> startGame(Room room) async {}
}

const _game = GameState(
  players: {
    'host': PlayerState(id: 'host', username: 'Host'),
    'ana': PlayerState(id: 'ana', username: 'Ana'),
    'beto': PlayerState(id: 'beto', username: 'Beto'),
  },
  turnOrder: ['host', 'ana', 'beto'],
  totalRounds: 5,
  diamondTileId: 1,
  phase: GamePhase.minigame,
);

void main() {
  late FakeRoomService rooms;
  late _FakeGameService games;

  /// [settle] en false no espera a que todo se quede quieto: el reloj de un
  /// minijuego nunca se queda quieto mientras se juega.
  Future<void> pumpBoard(
    WidgetTester tester, {
    required String me,
    bool settle = true,
  }) async {
    tester.view
      ..physicalSize = const Size(400, 1600)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          gameServiceProvider.overrideWithValue(games),
          roomServiceProvider.overrideWithValue(rooms),
          presenceServiceProvider.overrideWithValue(FakePresenceService()),
          userProfileProvider.overrideWith((ref) => Stream.value(null)),
          roomIdentityProvider.overrideWith(
            (ref) async => RoomIdentity(uid: me, username: me),
          ),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: FilledButton(
                  onPressed: () => Navigator.of(
                    context,
                  ).push(BoardScreen.route('sala', isHost: me == 'host')),
                  child: const Text('Abrir'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Abrir'));
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
    }
  }

  setUp(() {
    rooms = FakeRoomService()..put(testRoom());
    games = _FakeGameService()..emit(_game);
  });

  testWidgets('si Ana pasa a ser anfitriona, empieza a aplicar las acciones', (
    tester,
  ) async {
    await pumpBoard(tester, me: 'ana');
    expect(games.hosting, 0);
    expect(find.text('Esperando el minijuego...'), findsOneWidget);
    // Guardó la partida en curso para poder volver.
    expect(rooms.activeGames['ana'], 'sala');

    // El anfitrión se fue: Ana toma el lugar (lo haría su RoomGuard).
    await rooms.claimHost(roomId: 'sala', expectedHost: 'host', uid: 'ana');
    await tester.pump();
    await tester.pump();

    expect(games.hosting, 1);
    // El botón provisional ya no existe: el minijuego lo cierra el árbitro.
    expect(find.text('Simular minijuego'), findsNothing);
    expect(find.text('Esperando el minijuego...'), findsOneWidget);
  });

  testWidgets('el minijuego se juega en lugar del mapa y manda la jugada', (
    tester,
  ) async {
    games.emit(
      _game.copyWith(
        minigame: const MinigameState(
          type: MinigameType.stopwatch,
          round: 1,
          players: ['host', 'ana', 'beto'],
          targetMs: 5000,
        ),
      ),
    );
    await pumpBoard(tester, me: 'ana', settle: false);
    expect(find.text('Minijuego: Para el Tiempo'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 3000 + 4500));
    await tester.tap(find.text('¡Ya!'));
    await tester.pump();
    final move = games.sent.whereType<MinigameMove>().single;
    expect((move.playerId, move.round), ('ana', 1));
    // Cuenta desde que se mostró el minijuego (después de abrir la pantalla).
    expect(move.score, inInclusiveRange(4500, 5100));
  });

  testWidgets('el anfitrión que pierde el lugar deja de aplicarlas', (
    tester,
  ) async {
    await pumpBoard(tester, me: 'host');
    expect(games.hosting, 1);

    await rooms.claimHost(roomId: 'sala', expectedHost: 'host', uid: 'ana');
    await tester.pump();
    await tester.pump();

    expect(games.hosting, 0);
  });

  testWidgets('salir a mitad de partida pregunta y luego sale de la sala', (
    tester,
  ) async {
    await pumpBoard(tester, me: 'beto');

    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    unawaited(navigator.maybePop());
    await tester.pumpAndSettle();
    expect(find.text('Salir de la partida'), findsOneWidget);

    await tester.tap(find.text('Salir de la partida'));
    await tester.pumpAndSettle();

    expect(rooms.left, [('sala', 'beto')]);
    expect(rooms.activeGames['beto'], isNull);
    expect(find.text('Abrir'), findsOneWidget);
  });

  group('aviso de partida en curso', () {
    Future<void> pumpBanner(WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            roomServiceProvider.overrideWithValue(rooms),
            gameServiceProvider.overrideWithValue(games),
            presenceServiceProvider.overrideWithValue(FakePresenceService()),
            userProfileProvider.overrideWith((ref) => Stream.value(null)),
            activeGameProvider.overrideWith(
              (ref) => rooms.watchActiveGame('ana'),
            ),
            roomIdentityProvider.overrideWith(
              (ref) async => const RoomIdentity(uid: 'ana', username: 'Ana'),
            ),
          ],
          child: const MaterialApp(home: Scaffold(body: ActiveGameBanner())),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('ofrece volver y abre la partida', (tester) async {
      rooms.activeGames['ana'] = 'sala';
      await pumpBanner(tester);

      expect(find.text('Tienes una partida en curso'), findsOneWidget);
      await tester.tap(find.text('Volver'));
      await tester.pumpAndSettle();
      expect(find.byType(BoardScreen), findsOneWidget);
    });

    testWidgets('si la sala ya no existe, se olvida de ella', (tester) async {
      rooms.activeGames['ana'] = 'otra';
      await pumpBanner(tester);

      expect(find.text('Tienes una partida en curso'), findsNothing);
      expect(rooms.activeGames['ana'], isNull);
    });
  });
}
