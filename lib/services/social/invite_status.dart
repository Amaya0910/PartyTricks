import 'package:party_tricks/models/room.dart';

/// Qué muestra el botón de una invitación según cómo está la sala.
enum InviteStatus {
  /// La sala espera jugadores: se puede entrar.
  open('Unirse'),

  /// La partida ya arrancó.
  started('La party ya empezó'),

  /// La sala se cerró o ya no existe.
  closed('La party se cerró'),

  /// Todavía no se sabe (la sala está cargando).
  loading('Revisando...');

  const InviteStatus(this.label);

  final String label;

  bool get canJoin => this == InviteStatus.open;

  /// [room] es null si la sala ya no existe.
  static InviteStatus of(Room? room) {
    if (room == null) return InviteStatus.closed;
    return switch (room.status) {
      RoomStatus.waiting => InviteStatus.open,
      RoomStatus.playing => InviteStatus.started,
      RoomStatus.closed => InviteStatus.closed,
    };
  }
}
