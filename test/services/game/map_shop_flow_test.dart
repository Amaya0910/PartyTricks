import 'package:flutter_test/flutter_test.dart';
import 'package:party_tricks/services/game/game_service.dart';
import 'package:party_tricks/services/game_engine/award_calculator.dart';
import 'package:party_tricks/services/game_engine/board_layout.dart';
import 'package:party_tricks/services/game_engine/game_action.dart';
import 'package:party_tricks/services/game_engine/game_codec.dart';
import 'package:party_tricks/services/game_engine/game_engine.dart';
import 'package:party_tricks/services/game_engine/game_state.dart';
import 'package:party_tricks/services/game_engine/shop_items.dart';
import 'package:party_tricks/services/game_engine/turn_order_resolver.dart';

import '../game_engine/fake_random_source.dart';

/// Hace de Realtime Database y del anfitrión: guarda el estado como mapa y
/// aplica cada acción con [hostApply], igual que `FirebaseGameService`.
class _FakeRoom {
  _FakeRoom(this.engine, GameState start) : _stored = codec.encodeState(start);

  static const codec = GameCodec();

  final GameEngine engine;
  Map<String, Object?> _stored;

  GameState get state => codec.decodeState(_stored);

  /// Devuelve false si el anfitrión la ignoró.
  bool send(GameAction action) {
    final next = hostApply(engine, _stored, codec.encodeAction(action));
    if (next == null) return false;
    _stored = next;
    return true;
  }
}

void main() {
  test('partida de 3 rondas con tienda, trampa y escudo en el mapa real', () {
    // En el mapa real la 1 es bifurcación (desvío A: 32...36 -> 8), la 36
    // es tienda, la 8 positiva y la 9 negativa.
    final engine = GameEngine(
      board: buildDefaultBoard(),
      // Diamante (índice 38 = casilla 41) y luego los dados en orden.
      random: FakeRandomSource([38, 6, 1, 1, 2, 1, 6]),
    );
    final room = _FakeRoom(
      engine,
      engine.start(
        initialRolls: const [
          InitialRoll(playerId: 'b', username: 'Beto', value: 6),
          InitialRoll(playerId: 'a', username: 'Ana', value: 2),
        ],
        totalRounds: 3,
      ),
    );
    expect(room.state.diamondTileId, 41);

    // Ronda 1. Beto saca 6, toma el desvío y cae en la tienda 36.
    expect(room.send(const RollDice('b')), isTrue);
    expect(room.send(const ChooseBranch('b', 1)), isTrue);
    expect(room.state.phase, GamePhase.shopping);
    expect(room.state.players['b']!.position, 36);

    // Ana no puede comprar ni lanzar mientras Beto está en la tienda.
    expect(room.send(const BuyItem('a', ShopItem.shield)), isFalse);
    expect(room.send(const RollDice('a')), isFalse);

    expect(room.send(const BuyItem('b', ShopItem.trap)), isTrue);
    expect(room.send(const BuyItem('b', ShopItem.shield)), isTrue);
    // Ya gastó sus 10 monedas.
    expect(room.send(const BuyItem('b', ShopItem.extraDie3)), isFalse);
    expect(room.state.players['b']!.coins, 0);
    expect(room.send(const LeaveShop('b')), isTrue);
    // Salir dos veces no hace nada.
    expect(room.send(const LeaveShop('b')), isFalse);

    // Ana saca 1 y cae en la 1 (positiva).
    expect(room.send(const RollDice('a')), isTrue);
    expect(room.send(const FinishMinigame(['a'])), isTrue);

    // Ronda 2. La trampa no se puede poner en la tienda.
    expect(room.send(const UseItem('b', ShopItem.trap)), isFalse);
    expect(room.send(const RollDice('b')), isTrue); // 36 -> 8 (+3)
    expect(room.send(const RollDice('a')), isTrue); // Para en la 1.
    expect(room.send(const ChooseBranch('a', 0)), isTrue); // 1 -> 2 -> 3
    expect(room.send(const FinishMinigame([])), isTrue);

    // Ronda 3. Beto pone la trampa en la 8 y cae en la 9 (negativa): el
    // escudo lo protege.
    expect(room.send(const UseItem('b', ShopItem.trap)), isTrue);
    expect(room.state.traps, {8: 'b'});
    expect(room.send(const RollDice('b')), isTrue);
    var beto = room.state.players['b']!;
    expect(beto.position, 9);
    expect(beto.coins, 3);
    expect(beto.inventory, isEmpty);

    // Ana saca 6: pasa por la trampa de la 8 y cae en la 9.
    expect(room.send(const RollDice('a')), isTrue);
    final ana = room.state.players['a']!;
    expect(ana.position, 9);
    // 10 + 3 + 10 (minijuego) + 3 - 5 (trampa) - 3 (negativa).
    expect(ana.coins, 18);
    beto = room.state.players['b']!;
    expect(beto.coins, 8);
    expect(room.state.traps, isEmpty);

    expect(room.send(const FinishMinigame([])), isTrue);
    final end = room.state;
    expect(end.phase, GamePhase.finished);

    // Lo que se guardó sirve para los premios y las estadísticas.
    expect(end.players['b']!.purchases, 2);
    expect(end.players['b']!.itemsUsed, 2);
    final result = const AwardCalculator().calculate(end);
    expect(result.awards[FinalAward.topBuyer], ['b']);
  });

  test('el anfitrión ignora acciones que no entiende', () {
    final engine = GameEngine(
      board: buildDefaultBoard(),
      random: FakeRandomSource([0]),
    );
    final start = engine.start(
      initialRolls: const [
        InitialRoll(playerId: 'a', username: 'Ana', value: 1),
      ],
      totalRounds: 5,
    );
    final stored = const GameCodec().encodeState(start);

    expect(
      hostApply(engine, stored, {
        'type': 'useItem',
        'playerId': 'a',
        'item': 'cohete',
      }),
      isNull,
    );
    expect(hostApply(engine, stored, {'type': 'volar'}), isNull);
  });
}
