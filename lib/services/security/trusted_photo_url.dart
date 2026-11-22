/// Fotos de perfil que la app acepta descargar (H-03).
///
/// La URL de la foto la escribe el propio jugador (por ejemplo, en la sala),
/// así que no se descarga cualquier cosa: una URL de otro servidor podría
/// registrar la IP de quien la ve, y una por http viajaría sin cifrar. Solo se
/// aceptan fotos por HTTPS del servidor de fotos de las cuentas de Google.
///
/// Es la misma lista que revisan `database.rules.json` y `firestore.rules`.
abstract final class TrustedPhotoUrl {
  /// Largo máximo, igual que en las reglas.
  static const int maxLength = 2048;

  /// Servidores de los que se aceptan fotos.
  static const Set<String> allowedHosts = {'lh3.googleusercontent.com'};

  /// Si [url] se puede descargar sin riesgo.
  static bool isTrusted(String url) {
    if (url.isEmpty || url.length > maxLength) return false;
    final uri = Uri.tryParse(url);
    return uri != null &&
        uri.scheme == 'https' &&
        allowedHosts.contains(uri.host) &&
        !uri.hasPort &&
        uri.userInfo.isEmpty &&
        uri.path.length > 1;
  }
}
