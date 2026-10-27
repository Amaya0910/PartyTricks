/// Error de amigos, chat o invitaciones, con un mensaje para mostrar.
class SocialException implements Exception {
  const SocialException(this.message);

  final String message;

  @override
  String toString() => message;
}
