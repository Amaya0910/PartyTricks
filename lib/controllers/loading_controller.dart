import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:party_tricks/models/loading_state.dart';

/// Lleva el avance de la carga inicial.
///
/// Por ahora es simulado. Cuando exista Firebase, aquí se espera la
/// inicialización real y se actualiza `progress` según lo que vaya terminando.
class LoadingController extends Notifier<LoadingState> {
  static const Duration _tick = Duration(milliseconds: 50);
  static const Duration _duration = Duration(seconds: 3);
  // Tiempo que se queda en 100 % antes de pasar a la app.
  static const Duration _hold = Duration(milliseconds: 500);

  @override
  LoadingState build() {
    final timer = Timer.periodic(_tick, _onTick);
    ref.onDispose(timer.cancel);
    return const LoadingState(progress: 0, isDone: false);
  }

  void _onTick(Timer timer) {
    final elapsed = _tick * timer.tick;
    final progress =
        (elapsed.inMilliseconds / _duration.inMilliseconds)
            .clamp(0.0, 1.0)
            .toDouble();
    final isDone = elapsed >= _duration + _hold;

    state = LoadingState(progress: progress, isDone: isDone);
    if (isDone) timer.cancel();
  }
}

final loadingControllerProvider =
    NotifierProvider<LoadingController, LoadingState>(
  LoadingController.new,
);