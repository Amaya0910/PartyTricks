/// Estado de la pantalla de carga.
class LoadingState {
  const LoadingState({required this.progress, required this.isDone});

  /// Avance de 0.0 a 1.0.
  final double progress;

  /// true cuando terminó la carga y se puede mostrar la app.
  final bool isDone;
}