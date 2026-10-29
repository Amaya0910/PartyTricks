import 'package:flutter_test/flutter_test.dart';
import 'package:party_tricks/services/game/minigame_referee.dart';
import 'package:party_tricks/services/game_engine/game_state.dart';
import 'package:party_tricks/services/game_engine/minigames.dart';

const _rules = MinigameRules();
final _start = DateTime(2026, 10, 29, 20);

GameState _game({MinigameState? minigame, GamePhase? phase}) {
  return GameState(
    players: const {
      'ana': PlayerState(id: 'ana', username: 'Ana'),
      'beto': PlayerState(id: 'beto', username: 'Beto'),
    },
    turnOrder: const ['ana', 'beto'],
    totalRounds: 5,
    round: 2,
    diamondTileId: 1,
    phase: phase ?? GamePhase.minigame,
    minigame: minigame,
  );
}

const _stopwatch = MinigameState(
  type: MinigameType.stopwatch,
  round: 2,
  players: ['ana', 'beto'],
  targetMs: 9000,
);

void main() {
  test('no cierra antes del tiempo límite; después sí, una vez', () {
    final referee = MinigameReferee();
    final game = _game(minigame: _stopwatch);
    final limit = _rules.timeLimit(_stopwatch);

    expect(referee.check(game, _start), isNull, reason: 'empieza a contar');
    expect(
      referee.check(game, _start.add(limit - const Duration(seconds: 1))),
      isNull,
    );
    final timeout = referee.check(game, _start.add(limit))!;
    expect((timeout.round, timeout.step), (2, 0));
    expect(
      referee.check(game, _start.add(limit + const Duration(seconds: 1))),
      isNull,
      reason: 'no lo pide dos veces seguidas',
    );
  });

  test('si la acción se perdió, la vuelve a pedir pasado otro plazo', () {
    final referee = MinigameReferee();
    final game = _game(minigame: _stopwatch);
    final limit = _rules.timeLimit(_stopwatch);
    referee.check(game, _start);
    expect(referee.check(game, _start.add(limit)), isNotNull);
    expect(referee.check(game, _start.add(limit * 2)), isNotNull);
  });

  test('cada jugada reinicia la cuenta', () {
    final referee = MinigameReferee();
    const balloon = MinigameState(
      type: MinigameType.balloon,
      round: 2,
      players: ['ana', 'beto'],
      capacity: 40,
    );
    final turn = Duration(milliseconds: _rules.balloonTurnMs + _rules.graceMs);
    referee.check(_game(minigame: balloon), _start);
    // Ana infló justo antes de que se acabara su turno.
    final moved = balloon.copyWith(step: 1, pumps: 2, turn: 1);
    final later = _start.add(turn);
    expect(referee.check(_game(minigame: moved), later), isNull);
    expect(
      referee.check(_game(minigame: moved), later.add(turn))!.step,
      1,
      reason: 'sin explicación, el segundo turno dura solo el turno',
    );
  });

  test('fuera del minijuego no hace nada y olvida la cuenta', () {
    final referee = MinigameReferee();
    referee.check(_game(minigame: _stopwatch), _start);
    expect(
      referee.check(
        _game(phase: GamePhase.rolling),
        _start.add(const Duration(minutes: 5)),
      ),
      isNull,
    );
    expect(
      referee.check(
        _game(minigame: _stopwatch),
        _start.add(const Duration(minutes: 5)),
      ),
      isNull,
      reason: 'vuelve a empezar a contar',
    );
  });

  test(
    'partida vieja sin minijuego armado: la destraba a los pocos segundos',
    () {
      final referee = MinigameReferee();
      referee.check(_game(), _start);
      final timeout = referee.check(
        _game(),
        _start.add(Duration(milliseconds: _rules.legacyWaitMs)),
      );
      expect((timeout!.round, timeout.step), (2, 0));
    },
  );
}
