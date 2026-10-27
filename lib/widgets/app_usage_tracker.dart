import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:party_tricks/controllers/stats_controller.dart';
import 'package:party_tricks/services/stats/stats_providers.dart';

/// Mide el tiempo que la app está abierta y en primer plano, y marca el día
/// como activo para la racha. No dibuja nada: solo envuelve a [child].
///
/// El tiempo se guarda al pasar a segundo plano, al cerrar sesión y cada
/// [flushEvery], para no perderlo si el sistema cierra la app.
class AppUsageTracker extends ConsumerStatefulWidget {
  const AppUsageTracker({
    super.key,
    required this.child,
    this.flushEvery = const Duration(minutes: 1),
  });

  final Widget child;
  final Duration flushEvery;

  @override
  ConsumerState<AppUsageTracker> createState() => _AppUsageTrackerState();
}

class _AppUsageTrackerState extends ConsumerState<AppUsageTracker> {
  late final AppLifecycleListener _lifecycle;
  late final StatsController _stats;
  late final DateTime Function() _clock;
  Timer? _timer;

  /// Desde cuándo está en primer plano; null si está en segundo plano.
  DateTime? _since;

  @override
  void initState() {
    super.initState();
    // Se guardan aquí para poder usarlos en dispose, cuando ref ya no sirve.
    _stats = ref.read(statsControllerProvider);
    _clock = ref.read(clockProvider);
    _lifecycle = AppLifecycleListener(onResume: _start, onPause: _stop);
    _start();
  }

  @override
  void dispose() {
    _stop();
    _lifecycle.dispose();
    super.dispose();
  }

  void _start() {
    if (_since != null) return;
    _since = _clock();
    _stats.registerActivity();
    _timer = Timer.periodic(widget.flushEvery, (_) => _flush());
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
    _flush();
    _since = null;
  }

  /// Guarda el tiempo desde [_since] y vuelve a empezar a contar.
  void _flush() {
    final since = _since;
    if (since == null) return;
    final now = _clock();
    _since = now;
    _stats.addAppTime(now.difference(since));
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
