import 'package:flutter_test/flutter_test.dart';
import 'package:party_tricks/services/game_engine/game_state.dart';
import 'package:party_tricks/services/stats/match_time_tracker.dart';

void main() {
  late DateTime now;
  late MatchTimeTracker tracker;

  setUp(() {
    now = DateTime(2026, 10, 27, 18);
    tracker = MatchTimeTracker(clock: () => now);
  });

  void after(Duration time, GamePhase phase) {
    now = now.add(time);
    tracker.onPhase(phase);
  }

  test('sin avisos, los tiempos son cero', () {
    expect(tracker.playingTime, Duration.zero);
    expect(tracker.minigameTime, Duration.zero);
    expect(tracker.isFinished, isFalse);
  });

  test('mide la partida y los minijuegos por separado', () {
    tracker.onPhase(GamePhase.rolling);
    after(const Duration(minutes: 3), GamePhase.minigame);
    after(const Duration(minutes: 2), GamePhase.rolling);
    after(const Duration(minutes: 4), GamePhase.minigame);
    after(const Duration(minutes: 1), GamePhase.finished);

    expect(tracker.isFinished, isTrue);
    expect(tracker.playingTime, const Duration(minutes: 10));
    expect(tracker.minigameTime, const Duration(minutes: 3));
  });

  test('avisar la misma fase varias veces no reinicia el minijuego', () {
    tracker.onPhase(GamePhase.minigame);
    after(const Duration(minutes: 1), GamePhase.minigame);
    after(const Duration(minutes: 1), GamePhase.rolling);

    expect(tracker.minigameTime, const Duration(minutes: 2));
  });

  test('después de terminar, ya no cuenta más tiempo', () {
    tracker.onPhase(GamePhase.rolling);
    after(const Duration(minutes: 5), GamePhase.finished);
    now = now.add(const Duration(hours: 1));

    expect(tracker.playingTime, const Duration(minutes: 5));
  });

  test('si la partida sigue, cuenta hasta ahora', () {
    tracker.onPhase(GamePhase.rolling);
    after(const Duration(minutes: 2), GamePhase.minigame);
    now = now.add(const Duration(minutes: 1));

    expect(tracker.playingTime, const Duration(minutes: 3));
    expect(tracker.minigameTime, const Duration(minutes: 1));
  });
}
