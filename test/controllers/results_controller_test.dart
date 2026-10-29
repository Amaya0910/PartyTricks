import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:party_tricks/controllers/results_controller.dart';
import 'package:party_tricks/services/game_engine/game_state.dart';
import 'package:party_tricks/services/results/results_providers.dart';

import '../services/results/fake_results_service.dart';

GameState _game(GamePhase phase) {
  return GameState(
    players: const {
      'a': PlayerState(id: 'a', username: 'Ana', diamonds: 3),
      'b': PlayerState(id: 'b', username: 'Beto', diamonds: 1),
    },
    turnOrder: const ['a', 'b'],
    totalRounds: 5,
    round: 5,
    diamondTileId: 1,
    phase: phase,
  );
}

void main() {
  late FakeResultsService service;
  late ResultsController controller;

  setUp(() {
    service = FakeResultsService();
    final container = ProviderContainer(
      overrides: [resultsServiceProvider.overrideWithValue(service)],
    );
    addTearDown(container.dispose);
    controller = container.read(resultsControllerProvider);
  });

  test('guarda el resultado de la partida terminada', () async {
    final saved = await controller.saveFinishedMatch(
      roomId: 'sala-1',
      hostUid: 'a',
      game: _game(GamePhase.finished),
      isPublic: true,
    );

    expect(saved, isTrue);
    final record = service.saved['sala-1']!;
    expect(record.hostUid, 'a');
    expect(record.isPublic, isTrue);
    expect(record.results.winnerIds, ['a']);
    expect(record.results.ranking, hasLength(2));
  });

  test('no guarda una partida que no ha terminado', () async {
    final saved = await controller.saveFinishedMatch(
      roomId: 'sala-1',
      hostUid: 'a',
      game: _game(GamePhase.minigame),
    );

    expect(saved, isFalse);
    expect(service.saved, isEmpty);
  });

  test('si falla, avisa con false sin lanzar el error', () async {
    service.nextError = Exception('sin conexión');

    final saved = await controller.saveFinishedMatch(
      roomId: 'sala-1',
      hostUid: 'a',
      game: _game(GamePhase.finished),
    );

    expect(saved, isFalse);
  });
}
