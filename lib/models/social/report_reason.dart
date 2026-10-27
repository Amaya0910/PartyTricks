/// Motivos para reportar a un jugador (ver `decisiones.md`, D-10).
enum ReportReason {
  offensiveLanguage('Lenguaje ofensivo'),
  harassment('Acoso o burlas'),
  inappropriateContent('Contenido inapropiado'),
  other('Otro');

  const ReportReason(this.label);

  /// Texto que ve el jugador.
  final String label;
}
