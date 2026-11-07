import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:party_tricks/services/game/game_service.dart';
import 'package:party_tricks/services/game/minigame_referee.dart';
import 'package:party_tricks/services/game_engine/board_layout.dart';
import 'package:party_tricks/services/game_engine/game_action.dart';
import 'package:party_tricks/services/game_engine/game_codec.dart';
import 'package:party_tricks/services/game_engine/game_engine.dart';
import 'package:party_tricks/services/game_engine/game_state.dart';
import 'package:party_tricks/services/game_engine/minigames.dart';
import 'package:party_tricks/services/game_engine/random_source.dart';

import 'fake_random_source.dart';

const _rules = MinigameRules();
const _players = ['ana', 'beto', 'caro'];

MinigameJudge _judge(List<int> randomValues) =>
    MinigameJudge(random: FakeRandomSource(randomValues));

int _pick(MinigameState minigame, int value) =>
    MinigamePick.encode(minigame.stage, value);

/// Cada uno elige [picks] en la vuelta actual, en orden.
MinigameOutcome _round(
  MinigameJudge judge,
  MinigameState minigame,
  Map<String, int> picks,
) {
  MinigameOutcome outcome = (state: minigame, result: null);
  picks.forEach((id, value) {
    outcome = judge.play(outcome.state!, id, _pick(outcome.state!, value));
  });
  return outcome;
}

void main() {
  group('los que juega cada uno por su lado', () {
    const solo = [
      MinigameType.rhythm,
      MinigameType.diceMemory,
      MinigameType.coinRain,
      MinigameType.colorTrap,
      MinigameType.quickMath,
      MinigameType.safeLock,
    ];

    MinigameOutcome finish(MinigameType type, Map<String, int> scores) {
      final judge = _judge([55, 1, 2, 3, 4, 5, 6]);
      MinigameOutcome outcome = judge.start(type, 1, _players);
      scores.forEach((id, score) {
        outcome = judge.play(outcome.state!, id, score);
      });
      return outcome;
    }

    test('todos reciben la misma semilla', () {
      for (final type in solo) {
        final start = _judge([55]).start(type, 1, _players).state!;
        expect(start.seed, 55, reason: type.name);
      }
    });

    test('los minijuegos de antes no gastan azar en la semilla', () {
      final start = _judge([12]).start(MinigameType.stopwatch, 1, _players);
      expect(start.state!.seed, 0);
    });

    test('en Pulso Perfecto gana el que menos se desvía', () {
      final end = finish(MinigameType.rhythm, {
        'ana': 90,
        'beto': 35,
        'caro': 61,
      });
      expect(end.result!.winnerIds, ['beto']);
    });

    test('en los de puntos gana el que más hizo', () {
      for (final type in solo.where((type) => type != MinigameType.rhythm)) {
        final end = finish(type, {'ana': 5, 'beto': 9, 'caro': 2});
        expect(end.result!.winnerIds, ['beto'], reason: type.name);
        expect(end.result!.scores, {'ana': 5, 'beto': 9, 'caro': 2});
      }
    });

    test('si empatan, se desempata con el dado', () {
      final end = finish(MinigameType.coinRain, {
        'ana': 9,
        'beto': 9,
        'caro': 2,
      });
      // Dados 1 y 2 del azar de prueba.
      expect(end.result!.winnerIds, ['beto']);
      expect(end.result!.tiebreak, {
        'ana': [1],
        'beto': [2],
      });
    });

    test('con 0 puntos no se gana', () {
      final end = finish(MinigameType.diceMemory, {
        'ana': 0,
        'beto': 0,
        'caro': 0,
      });
      expect(end.result!.winnerIds, isEmpty);
    });

    test('en Pulso Perfecto, 0 ms de desvío sí vale', () {
      final end = finish(MinigameType.rhythm, {'ana': 0, 'beto': 3, 'caro': 9});
      expect(end.result!.winnerIds, ['ana']);
    });

    test('no se acepta un puntaje imposible', () {
      for (final type in solo) {
        final judge = _judge([55]);
        final start = judge.start(type, 1, _players).state!;
        expect(
          () => judge.play(start, 'ana', _rules.maxScore(type) + 1),
          throwsStateError,
          reason: type.name,
        );
      }
    });

    test('todos los puntajes caben en lo que acepta la base de datos', () {
      for (final type in MinigameType.values) {
        expect(
          _rules.maxScore(type),
          lessThanOrEqualTo(25000),
          reason: '$type',
        );
      }
    });

    test('si alguien no termina, se cierra sin él', () {
      final judge = _judge([55]);
      final start = judge.start(MinigameType.quickMath, 1, _players).state!;
      final after = judge.play(start, 'ana', 40).state!;
      final end = judge.timeout(after, after.step);
      expect(end.result!.winnerIds, ['ana']);
      expect(end.result!.scores['beto'], MinigameRules.noScore);
    });
  });

  group('Cables Rojos', () {
    test('tiene dos cables más que jugadores, y al menos cuatro', () {
      expect(_rules.wiresFor(2), 4);
      expect(_rules.wiresFor(3), 5);
      expect(_rules.wiresFor(6), 8);
      final start = _judge([]).start(MinigameType.wires, 1, _players).state!;
      expect(start.wires, 5);
      expect(start.cut, isEmpty);
    });

    test('cada ronda empieza un jugador distinto', () {
      final judge = _judge([]);
      expect(
        judge.start(MinigameType.wires, 2, _players).state!.balloonPlayer,
        'beto',
      );
    });

    test('un cable bueno pasa el turno', () {
      // 3 no es el cable malo.
      final judge = _judge([3]);
      final start = judge.start(MinigameType.wires, 1, _players).state!;
      final next = judge.play(start, 'ana', 2).state!;
      expect(next.cut, [2]);
      expect(next.balloonPlayer, 'beto');
      expect(next.step, 1);
      expect(next.out, isEmpty);
    });

    test('solo corta a quien le toca y cada cable una vez', () {
      final judge = _judge([3, 3]);
      final start = judge.start(MinigameType.wires, 1, _players).state!;
      expect(() => judge.play(start, 'beto', 0), throwsStateError);
      expect(() => judge.play(start, 'ana', 5), throwsStateError);
      final next = judge.play(start, 'ana', 2).state!;
      expect(() => judge.play(next, 'beto', 2), throwsStateError);
    });

    test('si explota, sale y hay bomba nueva para los que quedan', () {
      final judge = _judge([1]);
      final start = judge.start(MinigameType.wires, 1, _players).state!;
      final next = judge.play(start, 'ana', 2).state!;
      expect(next.out, ['ana']);
      expect(next.cursed, 2);
      expect(next.stage, 1);
      expect(next.cut, isEmpty);
      expect(next.wires, _rules.wiresFor(2));
      expect(next.balloonPlayer, 'beto');
      expect(next.ending, isFalse);
    });

    test('el último cable siempre explota', () {
      final judge = _judge([2, 2, 2, 2, 1]);
      var state = judge.start(MinigameType.wires, 1, _players).state!;
      for (final wire in [0, 1, 2, 3, 4]) {
        state = judge.play(state, state.balloonPlayer, wire).state!;
      }
      expect(state.out, hasLength(1));
    });

    test('el último en pie gana, después de ver la explosión', () {
      final judge = _judge([1, 1]);
      final start = judge.start(MinigameType.wires, 1, _players).state!;
      final second = judge.play(start, 'ana', 0).state!;
      final last = judge.play(second, 'beto', 0);
      expect(last.result, isNull, reason: 'primero se ve explotar');
      final ending = last.state!;
      expect(ending.ending, isTrue);
      expect(ending.cut, [0]);
      expect(() => judge.play(ending, 'caro', 1), throwsStateError);

      final end = judge.timeout(ending, ending.step);
      expect(end.state, isNull);
      expect(end.result!.winnerIds, ['caro']);
      expect(end.result!.out, ['ana', 'beto']);
    });

    test('si no corta a tiempo, se corta uno al azar por él', () {
      // Elige la posición 1 de los que quedan (el cable 1) y no explota.
      final judge = _judge([1, 3]);
      final start = judge.start(MinigameType.wires, 1, _players).state!;
      final next = judge.timeout(start, 0).state!;
      expect(next.cut, [1]);
      expect(next.balloonPlayer, 'beto');
    });

    test('solo, gana sin jugar', () {
      final solo = _judge([]).start(MinigameType.wires, 1, ['ana']);
      expect(solo.result!.winnerIds, ['ana']);
    });
  });

  group('Puja Secreta', () {
    MinigameState start(MinigameJudge judge) =>
        judge.start(MinigameType.secretBid, 1, _players).state!;

    test('todos empiezan con las mismas fichas', () {
      expect(start(_judge([])).chips, {'ana': 15, 'beto': 15, 'caro': 15});
    });

    test(
      'gana la vuelta la más alta que no se repita y se gastan las fichas',
      () {
        final judge = _judge([]);
        final next = _round(judge, start(judge), {
          'ana': 9,
          'beto': 9,
          'caro': 4,
        }).state!;
        expect(next.points, {'caro': 1});
        expect(next.chips, {'ana': 6, 'beto': 6, 'caro': 11});
        expect(next.picks, {'ana': 9, 'beto': 9, 'caro': 4});
        expect(next.stage, 1);
        expect(next.scores, isEmpty);
      },
    );

    test('no se puede pujar más de lo que se tiene', () {
      final judge = _judge([]);
      var state = start(judge);
      state = _round(judge, state, {'ana': 10, 'beto': 1, 'caro': 1}).state!;
      expect(state.chips['ana'], 5);
      expect(() => judge.play(state, 'ana', _pick(state, 6)), throwsStateError);
      expect(
        () => judge.play(state, 'beto', _pick(state, 11)),
        throwsStateError,
      );
    });

    test('se puede pasar para guardar fichas', () {
      final judge = _judge([]);
      final next = _round(judge, start(judge), {
        'ana': 0,
        'beto': 3,
        'caro': 2,
      }).state!;
      expect(next.chips['ana'], 15);
      expect(next.points, {'beto': 1});
    });

    test('solo se elige una vez y una jugada vieja no cuenta', () {
      final judge = _judge([]);
      final state = start(judge);
      final after = judge.play(state, 'ana', _pick(state, 3)).state!;
      expect(() => judge.play(after, 'ana', _pick(after, 4)), throwsStateError);
      final next = _round(judge, after.copyWith(), {
        'beto': 1,
        'caro': 2,
      }).state!;
      expect(
        () => judge.play(next, 'ana', MinigamePick.encode(0, 3)),
        throwsStateError,
        reason: 'esa jugada era de la vuelta anterior',
      );
    });

    test('quien no puja a tiempo no gasta ni gana', () {
      final judge = _judge([]);
      final state = start(judge);
      final after = judge.play(state, 'ana', _pick(state, 3)).state!;
      final next = judge.timeout(after, after.step).state!;
      expect(next.points, {'ana': 1});
      expect(next.chips, {'ana': 12, 'beto': 15, 'caro': 15});
      expect(next.picks, {'ana': 3, 'beto': 0, 'caro': 0});
    });

    test('después de la última vuelta gana quien ganó más', () {
      final judge = _judge([]);
      var state = start(judge);
      state = _round(judge, state, {'ana': 5, 'beto': 4, 'caro': 1}).state!;
      state = _round(judge, state, {'ana': 5, 'beto': 4, 'caro': 1}).state!;
      state = _round(judge, state, {'ana': 1, 'beto': 7, 'caro': 2}).state!;
      expect(state.ending, isTrue);
      final end = judge.timeout(state, state.step).result!;
      expect(end.winnerIds, ['ana']);
      expect(end.scores['ana'], 204, reason: '2 vueltas y 4 fichas');
      expect(end.scores['beto'], 100, reason: '1 vuelta y 0 fichas');
    });

    test('si ganaron lo mismo, gana quien guardó más fichas', () {
      final judge = _judge([]);
      var state = start(judge);
      state = _round(judge, state, {'ana': 6, 'beto': 2, 'caro': 1}).state!;
      state = _round(judge, state, {'ana': 1, 'beto': 4, 'caro': 2}).state!;
      state = _round(judge, state, {'ana': 0, 'beto': 0, 'caro': 0}).state!;
      final end = judge.timeout(state, state.step).result!;
      expect(end.winnerIds, ['beto']);
      expect(end.tiebreak, isEmpty);
    });

    test('si también guardaron lo mismo, se usa el dado', () {
      final judge = _judge([2, 6]);
      var state = start(judge);
      state = _round(judge, state, {'ana': 6, 'beto': 2, 'caro': 1}).state!;
      state = _round(judge, state, {'ana': 2, 'beto': 6, 'caro': 1}).state!;
      state = _round(judge, state, {'ana': 0, 'beto': 0, 'caro': 0}).state!;
      final end = judge.timeout(state, state.step).result!;
      expect(end.tiebreak.keys, ['ana', 'beto']);
      expect(end.winnerIds, ['beto']);
    });
  });

  group('Mayor o Menor', () {
    const low = 0;
    const high = 1;

    test('la primera carta no es de las puntas', () {
      expect(
        () => _judge([2]).start(MinigameType.highLow, 1, _players),
        throwsArgumentError,
        reason: 'el rango es de 3 a 11',
      );
      final start = _judge([7]).start(MinigameType.highLow, 1, _players);
      expect(start.state!.card, 7);
    });

    test('la siguiente nunca es igual a la anterior', () {
      // Un 7 del azar se convierte en 8: se salta la carta actual.
      final judge = _judge([7, 7]);
      final start = judge.start(MinigameType.highLow, 1, _players).state!;
      final next = _round(judge, start, {
        'ana': high,
        'beto': high,
        'caro': high,
      }).state!;
      expect(next.card, 8);
      expect(next.previousCard, 7);
    });

    test('los que fallan quedan fuera', () {
      final judge = _judge([7, 10]);
      final start = judge.start(MinigameType.highLow, 1, _players).state!;
      final next = _round(judge, start, {
        'ana': high,
        'beto': low,
        'caro': high,
      }).state!;
      expect(next.out, ['beto']);
      expect(next.alive, ['ana', 'caro']);
      expect(next.picks, {'ana': high, 'beto': low, 'caro': high});
      expect(next.ending, isFalse);
    });

    test('si fallan todos, siguen todos', () {
      final judge = _judge([7, 2]);
      final start = judge.start(MinigameType.highLow, 1, _players).state!;
      final next = _round(judge, start, {
        'ana': high,
        'beto': high,
        'caro': high,
      }).state!;
      expect(next.out, isEmpty);
      expect(next.stage, 1);
    });

    test('quien no apuesta a tiempo falla', () {
      final judge = _judge([7, 10]);
      final start = judge.start(MinigameType.highLow, 1, _players).state!;
      final after = judge.play(start, 'ana', _pick(start, high)).state!;
      final next = judge.timeout(after, after.step).state!;
      expect(next.out, ['beto', 'caro']);
      expect(next.ending, isTrue);
    });

    test('quien quedó fuera ya no apuesta', () {
      final judge = _judge([7, 10]);
      final start = judge.start(MinigameType.highLow, 1, _players).state!;
      final next = _round(judge, start, {
        'ana': high,
        'beto': low,
        'caro': high,
      }).state!;
      expect(
        () => judge.play(next, 'beto', _pick(next, high)),
        throwsStateError,
      );
    });

    test('gana el último, después de ver la carta', () {
      final judge = _judge([7, 10]);
      final start = judge.start(MinigameType.highLow, 1, _players).state!;
      final next = _round(judge, start, {
        'ana': high,
        'beto': low,
        'caro': low,
      }).state!;
      expect(next.ending, isTrue);
      final end = judge.timeout(next, next.step);
      expect(end.result!.winnerIds, ['ana']);
      expect(end.result!.out, ['beto', 'caro']);
    });

    test('si se acaban las cartas, se desempata con el dado', () {
      final cards = [for (var i = 0; i < _rules.highLowMaxCards; i++) 1];
      final judge = _judge([7, ...cards, 3, 5]);
      var state = judge.start(MinigameType.highLow, 1, ['ana', 'beto']).state!;
      for (var i = 0; i < _rules.highLowMaxCards; i++) {
        // Sale un 1: los dos fallan y siguen.
        state = _round(judge, state, {'ana': high, 'beto': high}).state!;
      }
      expect(state.ending, isTrue);
      final end = judge.timeout(state, state.step).result!;
      expect(end.winnerIds, ['beto']);
    });
  });

  group('La Silla Fantasma', () {
    test('todos empiezan con sus vidas', () {
      final start = _judge([]).start(MinigameType.ghostChair, 1, _players);
      expect(start.state!.points, {'ana': 2, 'beto': 2, 'caro': 2});
    });

    test('quien está en la silla maldita pierde una vida', () {
      final judge = _judge([1]);
      final start = judge.start(MinigameType.ghostChair, 1, _players).state!;
      final next = _round(judge, start, {
        'ana': 1,
        'beto': 1,
        'caro': 2,
      }).state!;
      expect(next.cursed, 1);
      expect(next.points, {'ana': 1, 'beto': 1, 'caro': 2});
      expect(next.picks, {'ana': 1, 'beto': 1, 'caro': 2});
      expect(next.out, isEmpty);
    });

    test('si el fantasma llega a una silla vacía, nadie pierde', () {
      final judge = _judge([0]);
      final start = judge.start(MinigameType.ghostChair, 1, _players).state!;
      final next = _round(judge, start, {
        'ana': 1,
        'beto': 1,
        'caro': 2,
      }).state!;
      expect(next.points, {'ana': 2, 'beto': 2, 'caro': 2});
    });

    test('sin vidas se sale', () {
      final judge = _judge([1, 1]);
      var state = judge.start(MinigameType.ghostChair, 1, _players).state!;
      state = _round(judge, state, {'ana': 1, 'beto': 0, 'caro': 2}).state!;
      state = _round(judge, state, {'ana': 1, 'beto': 0, 'caro': 2}).state!;
      expect(state.out, ['ana']);
      expect(state.alive, ['beto', 'caro']);
    });

    test('si salieran todos los que quedan, siguen con una vida', () {
      final judge = _judge([1, 1]);
      var state = judge.start(MinigameType.ghostChair, 1, [
        'ana',
        'beto',
      ]).state!;
      state = _round(judge, state, {'ana': 1, 'beto': 1}).state!;
      state = _round(judge, state, {'ana': 1, 'beto': 1}).state!;
      expect(state.out, isEmpty);
      expect(state.points, {'ana': 1, 'beto': 1});
    });

    test('quien no elige a tiempo se sienta en una al azar', () {
      // Beto cae en la silla 2, Caro en la 0 y el fantasma va a la 2.
      final judge = _judge([2, 0, 2]);
      final start = judge.start(MinigameType.ghostChair, 1, _players).state!;
      final after = judge.play(start, 'ana', _pick(start, 1)).state!;
      final next = judge.timeout(after, after.step).state!;
      expect(next.picks, {'ana': 1, 'beto': 2, 'caro': 0});
      expect(next.points['beto'], 1);
    });

    test('no se puede elegir una silla que no existe', () {
      final judge = _judge([]);
      final start = judge.start(MinigameType.ghostChair, 1, _players).state!;
      expect(
        () => judge.play(start, 'ana', _pick(start, _rules.chairs)),
        throwsStateError,
      );
    });

    test('gana el último, después de ver llegar al fantasma', () {
      final judge = _judge([1, 1]);
      var state = judge.start(MinigameType.ghostChair, 1, [
        'ana',
        'beto',
      ]).state!;
      state = _round(judge, state, {'ana': 1, 'beto': 0}).state!;
      state = _round(judge, state, {'ana': 1, 'beto': 0}).state!;
      expect(state.ending, isTrue);
      final end = judge.timeout(state, state.step).result!;
      expect(end.winnerIds, ['beto']);
      expect(end.out, ['ana']);
    });

    test('si se acaban las vueltas, gana quien tiene más vidas', () {
      final fantasma = [for (var i = 0; i < _rules.chairMaxStages; i++) 2];
      final judge = _judge([...fantasma, 3, 5]);
      var state = judge.start(MinigameType.ghostChair, 1, _players).state!;
      state = _round(judge, state, {'ana': 2, 'beto': 0, 'caro': 0}).state!;
      for (var i = 1; i < _rules.chairMaxStages; i++) {
        state = _round(judge, state, {'ana': 0, 'beto': 0, 'caro': 0}).state!;
      }
      expect(state.ending, isTrue);
      final end = judge.timeout(state, state.step).result!;
      expect(end.tiebreak.keys, ['beto', 'caro'], reason: 'ana tiene una vida');
    });
  });

  group('el árbitro', () {
    test('espera lo justo en cada minijuego', () {
      for (final type in MinigameType.values) {
        final minigame = MinigameState(
          type: type,
          round: 1,
          players: _players,
          wires: 5,
        );
        expect(
          _rules.timeLimit(minigame).inMilliseconds,
          greaterThan(_rules.introMs + _rules.graceMs),
          reason: type.name,
        );
      }
    });

    test('los que terminan solos alcanzan a jugarse completos', () {
      expect(
        _rules
            .timeLimit(
              const MinigameState(
                type: MinigameType.colorTrap,
                round: 1,
                players: _players,
              ),
            )
            .inMilliseconds,
        _rules.introMs +
            _rules.colorTrapRounds * _rules.colorTrapWordMs +
            _rules.graceMs,
      );
    });

    test('un minijuego que ya terminó solo espera a que se vea', () {
      const ending = MinigameState(
        type: MinigameType.highLow,
        round: 1,
        players: _players,
        stage: 2,
        ending: true,
      );
      expect(
        _rules.timeLimit(ending),
        Duration(milliseconds: _rules.highLowRevealMs),
      );
      expect(
        _rules.timeLimit(ending.copyWith(ending: false)),
        Duration(
          milliseconds:
              _rules.highLowRevealMs + _rules.highLowChoiceMs + _rules.graceMs,
        ),
      );
    });

    test('cierra por tiempo lo que ya terminó', () {
      const minigame = MinigameState(
        type: MinigameType.wires,
        round: 3,
        players: _players,
        step: 4,
        ending: true,
      );
      final game = GameState(
        players: const {'ana': PlayerState(id: 'ana', username: 'Ana')},
        turnOrder: const ['ana'],
        totalRounds: 5,
        round: 3,
        diamondTileId: 1,
        phase: GamePhase.minigame,
        minigame: minigame,
      );
      final referee = MinigameReferee();
      final start = DateTime(2026);
      expect(referee.check(game, start), isNull);
      final late = start.add(Duration(milliseconds: _rules.wiresBoomMs));
      final action = referee.check(game, late);
      expect(action, isNotNull);
      expect(action!.step, 4);
    });
  });

  group('partidas completas', () {
    /// Juega una vez [type] al azar, como lo haría el anfitrión: cada jugada
    /// pasa por la base de datos (codificada y decodificada).
    MinigameResult playOut(MinigameType type, int seed, List<String> ids) {
      final random = Random(seed);
      final engine = GameEngine(
        board: buildDefaultBoard(),
        random: DartRandomSource(Random(seed + 1)),
        minigames: [type],
      );
      const codec = GameCodec();
      var state = engine.apply(
        GameState(
          players: {
            for (final id in ids) id: PlayerState(id: id, username: id),
          },
          turnOrder: ids,
          totalRounds: 1,
          diamondTileId: 3,
          turnIndex: ids.length - 1,
          phase: GamePhase.shopping,
        ),
        LeaveShop(ids.last),
      );

      void send(GameAction action) {
        final next = hostApply(
          engine,
          codec.encodeState(state),
          codec.encodeAction(action),
        );
        expect(next, isNotNull, reason: 'la jugada no valió: $action');
        state = codec.decodeState(next!);
      }

      for (var turn = 0; turn < 500; turn++) {
        final minigame = state.minigame;
        if (minigame == null) return state.lastMinigame!;
        if (minigame.ending) {
          send(MinigameTimeout(1, minigame.step));
          continue;
        }
        // A veces alguien se distrae y se acaba el tiempo.
        if (random.nextInt(8) == 0) {
          send(MinigameTimeout(1, minigame.step));
          continue;
        }
        if (type == MinigameType.wires) {
          final left = [
            for (var wire = 0; wire < minigame.wires; wire++)
              if (!minigame.cut.contains(wire)) wire,
          ];
          send(
            MinigameMove(
              minigame.balloonPlayer,
              1,
              left[random.nextInt(left.length)],
            ),
          );
          continue;
        }
        final waiting = minigame.alive.firstWhere(
          (id) => !minigame.scores.containsKey(id),
        );
        final value = switch (type) {
          MinigameType.secretBid => random.nextInt(
            min(_rules.maxBid, minigame.chips[waiting] ?? 0) + 1,
          ),
          MinigameType.highLow => random.nextInt(2),
          MinigameType.ghostChair => random.nextInt(_rules.chairs),
          _ => random.nextInt(_rules.maxScore(type) + 1),
        };
        send(
          MinigameMove(
            waiting,
            1,
            type.playsInRounds ? _pick(minigame, value) : value,
          ),
        );
      }
      fail('$type no terminó');
    }

    test('los minijuegos nuevos siempre terminan, con cualquier jugada', () {
      final types = MinigameType.values.where(
        (type) =>
            type != MinigameType.stopwatch &&
            type != MinigameType.reaction &&
            type != MinigameType.balloon,
      );
      for (final type in types) {
        for (var seed = 0; seed < 40; seed++) {
          final ids = [
            'a',
            'b',
            'c',
            'd',
            'e',
            'f',
          ].take(2 + seed % 5).toList();
          final result = playOut(type, seed, ids);
          expect(result.type, type);
          expect(result.winnerIds.toSet().difference(ids.toSet()), isEmpty);
          if (type.needsRivals) {
            expect(result.winnerIds, hasLength(1), reason: '$type, $seed');
          }
          expect(result.out.toSet(), hasLength(result.out.length));
        }
      }
    });

    test('el estado de cada minijuego sobrevive a la base de datos', () {
      const codec = GameCodec();
      const original = MinigameState(
        type: MinigameType.ghostChair,
        round: 4,
        players: _players,
        step: 7,
        stage: 3,
        seed: 12345,
        wires: 6,
        cut: [1, 4],
        card: 9,
        previousCard: 2,
        points: {'ana': 1},
        chips: {'beto': 8},
        picks: {'caro': 2},
        cursed: 2,
        out: ['beto'],
        ending: true,
      );
      final game = GameState(
        players: const {'ana': PlayerState(id: 'ana', username: 'Ana')},
        turnOrder: const ['ana'],
        totalRounds: 5,
        diamondTileId: 1,
        phase: GamePhase.minigame,
        minigame: original,
      );
      final read = codec.decodeState(codec.encodeState(game)).minigame!;
      expect(read.type, MinigameType.ghostChair);
      expect(read.seed, 12345);
      expect(read.stage, 3);
      expect(read.wires, 6);
      expect(read.cut, [1, 4]);
      expect(read.card, 9);
      expect(read.previousCard, 2);
      expect(read.points, {'ana': 1});
      expect(read.chips, {'beto': 8});
      expect(read.picks, {'caro': 2});
      expect(read.cursed, 2);
      expect(read.out, ['beto']);
      expect(read.ending, isTrue);
    });

    test('una partida guardada antes de estos campos se sigue leyendo', () {
      const codec = GameCodec();
      final read = codec.decodeState({
        'players': {
          'ana': {'username': 'Ana'},
        },
        'turnOrder': ['ana'],
        'phase': 'minigame',
        'minigame': {
          'type': 'balloon',
          'round': 2,
          'players': ['ana'],
        },
      }).minigame!;
      expect(read.ending, isFalse);
      expect(read.cut, isEmpty);
      expect(read.points, isEmpty);
    });
  });

  group('los tipos de minijuego', () {
    test('cada tipo tiene al menos dos minijuegos', () {
      for (final category in MinigameCategory.values) {
        final minigames = MinigameType.values.where(
          (type) => type.category == category,
        );
        expect(minigames.length, greaterThan(1), reason: category.title);
      }
    });

    test('cada minijuego está donde corresponde', () {
      const expected = {
        MinigameCategory.reflexes: [
          MinigameType.reaction,
          MinigameType.coinRain,
        ],
        MinigameCategory.precision: [
          MinigameType.stopwatch,
          MinigameType.rhythm,
          MinigameType.safeLock,
        ],
        MinigameCategory.wits: [
          MinigameType.diceMemory,
          MinigameType.colorTrap,
          MinigameType.quickMath,
        ],
        MinigameCategory.luck: [
          MinigameType.wires,
          MinigameType.highLow,
          MinigameType.ghostChair,
        ],
        MinigameCategory.strategy: [
          MinigameType.balloon,
          MinigameType.secretBid,
        ],
      };
      expected.forEach((category, minigames) {
        for (final minigame in minigames) {
          expect(minigame.category, category, reason: minigame.title);
        }
      });
      expect(
        expected.values.expand((list) => list),
        unorderedEquals(MinigameType.values),
        reason: 'no puede quedar ninguno sin tipo',
      );
    });

    test('el id se lee de vuelta; uno desconocido no', () {
      for (final category in MinigameCategory.values) {
        expect(MinigameCategory.byId(category.name), category);
      }
      expect(MinigameCategory.byId('otro'), isNull);
      expect(MinigameCategory.byId(null), isNull);
    });
  });

  test('una jugada guarda la vuelta y lo elegido', () {
    final score = MinigamePick.encode(3, 7);
    expect(MinigamePick.stageOf(score), 3);
    expect(MinigamePick.valueOf(score), 7);
    final none = MinigamePick.encode(2, MinigamePick.none);
    expect(MinigamePick.valueOf(none), MinigamePick.none);
    expect(none, lessThanOrEqualTo(25000));
  });
}
