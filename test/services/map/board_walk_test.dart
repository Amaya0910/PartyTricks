import 'package:flutter_test/flutter_test.dart';
import 'package:party_tricks/services/game_engine/board_layout.dart';
import 'package:party_tricks/services/game_engine/game_action.dart';
import 'package:party_tricks/services/game_engine/game_engine.dart';
import 'package:party_tricks/services/game_engine/game_state.dart';
import 'package:party_tricks/services/map/board_walk.dart';

import '../game_engine/fake_random_source.dart';

List<int> _range(int from, int to) => [for (var i = from; i <= to; i++) i];

/// Ana detenida en la bifurcación [at] del primer mapa con [stepsLeft] pasos
/// por dar. El diamante está en el otro atajo (32…36), fuera de las rutas
/// que se prueban, para que no haga falta sortearlo.
GameState _stoppedAt(int at, int stepsLeft) => GameState(
  players: {'a': PlayerState(id: 'a', username: 'Ana', position: at)},
  turnOrder: const ['a'],
  totalRounds: 5,
  diamondTileId: 35,
  phase: GamePhase.choosingBranch,
  stepsLeft: stepsLeft,
);

void main() {
  final walk = BoardWalk(buildDefaultBoard());

  test('camina casilla por casilla por el camino principal', () {
    expect(walk.between(2, 5), [3, 4, 5]);
  });

  test('si no se mueve no camina', () {
    expect(walk.between(7, 7), isEmpty);
  });

  test('da la vuelta por la salida', () {
    expect(walk.between(30, 1), [31, 0, 1]);
  });

  test('entra al desvío desde la bifurcación', () {
    expect(walk.between(1, 34), [32, 33, 34]);
  });

  test('sale del desvío y vuelve al camino principal', () {
    expect(walk.between(40, 24), [41, 23, 24]);
  });

  group('después de elegir camino en una bifurcación', () {
    // Primer mapa: en la 13, el camino principal (14…22) llega a la 23 en
    // 10 pasos y el atajo (37…41) en 6.
    final main13 = [..._range(14, 23), 24];
    final shortcut13 = [..._range(37, 41), 23, 24];

    test('el error: sin saber de dónde venía, va por el atajo aunque haya '
        'elegido el camino principal', () {
      expect(walk.between(13, 24), shortcut13);
    });

    test('con los pasos que le quedaban, sigue el camino principal', () {
      expect(
        walk.between(13, 24, fork: (from: 13, steps: 11, branch: 0)),
        main13,
      );
      expect(
        walk.between(13, 24, fork: (from: 13, steps: 11, branch: null)),
        main13,
      );
    });

    test('si eligió el atajo, va por el atajo', () {
      expect(
        walk.between(13, 24, fork: (from: 13, steps: 7, branch: 1)),
        shortcut13,
      );
    });

    test('lo mismo en la otra bifurcación del primer mapa (la 1)', () {
      // Principal 2…7 → 8 en 7 pasos; atajo 32…36 → 8 en 6.
      expect(walk.between(1, 9), [..._range(32, 36), 8, 9]);
      expect(
        walk.between(1, 9, fork: (from: 1, steps: 8, branch: 0)),
        _range(2, 9),
      );
    });

    test('si los datos no cuadran, vuelve al camino más corto', () {
      // De otra casilla.
      expect(
        walk.between(13, 24, fork: (from: 12, steps: 11, branch: 0)),
        shortcut13,
      );
      // Pasos con los que no se llega.
      expect(
        walk.between(13, 24, fork: (from: 13, steps: 9, branch: 0)),
        shortcut13,
      );
      // Un camino que no existe o pasos absurdos.
      expect(
        walk.between(13, 24, fork: (from: 13, steps: 11, branch: 5)),
        shortcut13,
      );
      expect(
        walk.between(13, 24, fork: (from: 13, steps: 100000, branch: 0)),
        shortcut13,
      );
    });

    test('si dos caminos tienen el mismo largo, el elegido desempata', () {
      // 0 → (1, 2 | 3, 4) → 5 → salida: los dos caminos miden lo mismo.
      final walkEqual = BoardWalk(
        BoardLayout(const [
          BoardTile(id: 0, type: TileType.start, next: [1, 3]),
          BoardTile(id: 1, type: TileType.positive, next: [2]),
          BoardTile(id: 2, type: TileType.positive, next: [5]),
          BoardTile(id: 3, type: TileType.shop, next: [4]),
          BoardTile(id: 4, type: TileType.positive, next: [5]),
          BoardTile(id: 5, type: TileType.positive, next: [0]),
        ]),
      );

      expect(walkEqual.between(0, 5, fork: (from: 0, steps: 3, branch: 1)), [
        3,
        4,
        5,
      ]);
      expect(walkEqual.between(0, 5, fork: (from: 0, steps: 3, branch: 0)), [
        1,
        2,
        5,
      ]);
    });
  });

  group('forkWalkBetween con el motor de verdad', () {
    final engine = GameEngine(
      board: buildDefaultBoard(),
      random: FakeRandomSource(const []),
    );

    test('camino principal con pasos de sobra: 11 pasos desde la 13', () {
      final before = _stoppedAt(13, 11);
      final afterShop = engine.apply(before, const ChooseBranch('a', 0));
      final fork = forkWalkBetween(before, afterShop, 'a');

      // La 17 es una tienda: se detiene de paso, a 4 pasos de la 13, y le
      // quedan 7 por dar. El recorrido de este tramo llega solo hasta ahí.
      expect(afterShop.phase, GamePhase.shopping);
      expect(afterShop.players['a']!.position, 17);
      expect(afterShop.stepsLeft, 7);
      expect(fork, (from: 13, steps: 4, branch: 0));
      expect(walk.between(13, 17, fork: fork), _range(14, 17));

      // Al seguir camina el resto por el camino principal hasta la 24.
      final after = engine.apply(afterShop, const LeaveShop('a'));
      expect(after.players['a']!.position, 24);
      expect(walk.between(17, 24), [..._range(18, 23), 24]);
    });

    test(
      'si se vuelve a detener en otra bifurcación, cuenta solo hasta ahí',
      () {
        // De la 1 por el camino principal (12 pasos hasta la 13) y quedan 3.
        final before = _stoppedAt(1, 15);
        final after = engine.apply(before, const ChooseBranch('a', 0));
        final fork = forkWalkBetween(before, after, 'a');

        expect(after.phase, GamePhase.choosingBranch);
        expect(after.players['a']!.position, 13);
        expect(after.stepsLeft, 3);
        expect(fork, (from: 1, steps: 12, branch: 0));
        // El más corto iría por el atajo (11 pasos).
        expect(walk.between(1, 13), isNot(_range(2, 13)));
        expect(walk.between(1, 13, fork: fork), _range(2, 13));
      },
    );

    test('si eligió el atajo, lo dice', () {
      final before = _stoppedAt(13, 7);
      final after = engine.apply(before, const ChooseBranch('a', 1));

      expect(forkWalkBetween(before, after, 'a'), (
        from: 13,
        steps: 7,
        branch: 1,
      ));
    });

    test('un turno saltado en la bifurcación toma el camino principal', () {
      final before = _stoppedAt(13, 11);
      final after = engine.apply(before, const SkipTurn('a'));
      final fork = forkWalkBetween(before, after, 'a');

      // Camina por el principal hasta la tienda 17 (4 pasos) y ahí se detiene.
      expect(fork, (from: 13, steps: 4, branch: 0));
      expect(walk.between(13, 17, fork: fork).first, 14);
    });

    test(
      'si no estaba detenido en una bifurcación, no hay nada que seguir',
      () {
        final rolling = _stoppedAt(13, 0).copyWith(phase: GamePhase.rolling);

        expect(forkWalkBetween(rolling, rolling, 'a'), isNull);
        expect(forkWalkBetween(_stoppedAt(13, 11), rolling, 'b'), isNull);
      },
    );
  });
}
