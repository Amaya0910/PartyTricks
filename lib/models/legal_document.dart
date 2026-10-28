/// Una sección de un documento: título y párrafos.
class LegalSection {
  const LegalSection(this.heading, this.paragraphs);

  final String heading;
  final List<String> paragraphs;
}

/// Textos de "Más opciones" en Ajustes: Acerca de, Términos y condiciones y
/// Política de privacidad. Están escritos para un proyecto de aula con
/// jugadores de 10 a 27 años.
enum LegalDocument {
  about('Acerca de', _about),
  terms('Términos y condiciones', _terms),
  privacy('Política de privacidad', _privacy);

  const LegalDocument(this.title, this.sections);

  final String title;
  final List<LegalSection> sections;

  /// Fecha de la última actualización de los textos.
  static const updatedAt = '27 de octubre de 2026';

  /// A quién escribir.
  static const contact =
      'el equipo de Party Tricks (Isabella Amaya y Brayan Vasquez)';
}

const _about = [
  LegalSection('Party Tricks', [
    'Party Tricks es un juego multijugador por turnos: recorres un mapa '
        'lanzando dados, ganas o pierdes monedas según la casilla, compites '
        'en minijuegos cortos y te disputas los diamantes. Gana quien tenga '
        'más diamantes al final.',
  ]),
  LegalSection('Quiénes lo hacemos', [
    'Es un proyecto de aula de la materia Programación Móvil, hecho por '
        'Isabella Amaya y Brayan Vasquez.',
    'La app está hecha con Flutter y usa Firebase (de Google) para las '
        'cuentas, los datos y las partidas en línea.',
  ]),
  LegalSection('Versión', ['1.0.0']),
];

const _terms = [
  LegalSection('1. Qué es Party Tricks', [
    'Party Tricks es un juego gratuito creado como proyecto de aula. No es '
        'un producto comercial: no tiene compras con dinero real ni '
        'publicidad. Las monedas y los diamantes solo existen dentro del '
        'juego y no se pueden cambiar por dinero.',
  ]),
  LegalSection('2. Quién puede jugar', [
    'El juego está pensado para personas de 10 a 27 años.',
    'Si eres menor de edad, usa Party Tricks con permiso de tu madre, '
        'padre o acudiente, y muéstrales estos términos y la política de '
        'privacidad.',
  ]),
  LegalSection('3. Tu cuenta', [
    'Eres responsable de tu cuenta y de tu contraseña. No compartas tu '
        'contraseña con nadie.',
    'Tu nombre de usuario lo ven los demás jugadores. No uses tu nombre '
        'completo, tu dirección ni datos que permitan ubicarte. El nombre '
        'se puede cambiar una vez cada 30 días.',
  ]),
  LegalSection('4. Cómo comportarse', [
    'En el chat y en las partidas, trata a los demás con respeto. No está '
        'permitido:',
    '• Insultar, acosar, burlarse o amenazar a otros jugadores.',
    '• Enviar contenido sexual, violento o que discrimine a alguien.',
    '• Pedir o compartir datos personales: dirección, colegio, teléfono, '
        'fotos o redes sociales.',
    '• Hacer trampa o modificar la app para sacar ventaja.',
    'Si alguien te hace sentir incómodo, usa Bloquear y Reportar en su '
        'chat, y cuéntale a un adulto de confianza.',
  ]),
  LegalSection('5. Moderación', [
    'Los reportes los revisa el equipo o el docente. Podemos borrar '
        'mensajes o cerrar cuentas que no cumplan estas reglas.',
  ]),
  LegalSection('6. Cambios y disponibilidad', [
    'Como es un proyecto de aula, el juego puede cambiar, tener errores o '
        'dejar de estar disponible en cualquier momento. Si cambiamos estos '
        'términos, actualizaremos la fecha de abajo.',
  ]),
  LegalSection('7. Contacto', [
    'Si tienes dudas, escríbele a ${LegalDocument.contact}.',
    'Última actualización: ${LegalDocument.updatedAt}.',
  ]),
];

const _privacy = [
  LegalSection('1. Qué datos guardamos', [
    'Para que el juego funcione guardamos:',
    '• Tu correo y tu contraseña, en Firebase Authentication. La contraseña '
        'nunca la vemos nosotros.',
    '• Tu nombre de usuario, tu código de amistad, tu experiencia, tus '
        'monedas, tus diamantes y los cosméticos que tienes.',
    '• Tus estadísticas: partidas, minijuegos, tiempo en la app y rachas.',
    '• Tus amigos, tus mensajes del chat, tus invitaciones, a quién '
        'bloqueaste y los reportes que envías.',
    '• Tu foto de perfil, solo si decides tomarla. Es opcional.',
    'Tus preferencias (sonido, notificaciones) se quedan solo en tu '
        'celular.',
  ]),
  LegalSection('2. Para qué los usamos', [
    'Solo para que puedas jugar: entrar a tu cuenta, jugar en línea, '
        'agregar amigos, chatear y ver tus estadísticas.',
    'No vendemos, no alquilamos y no compartimos tus datos con nadie para '
        'publicidad.',
  ]),
  LegalSection('3. Quién ve qué', [
    'Los demás jugadores solo ven tu nombre de usuario, tu nivel y tu '
        'foto (si la pusiste). Tu correo nunca se muestra.',
    'Tus mensajes solo los ven tú y tu amigo. Si alguien reporta un chat, '
        'el equipo o el docente pueden revisarlo para proteger a los '
        'jugadores.',
  ]),
  LegalSection('4. Dónde se guardan', [
    'Los datos se guardan en Firebase, un servicio de Google, protegidos '
        'con reglas de seguridad para que cada jugador solo pueda ver y '
        'cambiar lo suyo.',
  ]),
  LegalSection('5. Menores de edad', [
    'Si eres menor de edad, tu madre, padre o acudiente debe estar de '
        'acuerdo con que uses el juego. Te pedimos solo los datos '
        'necesarios para jugar.',
  ]),
  LegalSection('6. Tus derechos', [
    'Puedes ver y cambiar tu nombre, tu correo y tu contraseña en Ajustes. '
        'Si quieres que borremos tu cuenta y tus datos, escríbele a '
        '${LegalDocument.contact}.',
  ]),
  LegalSection('7. Contacto', [
    'Si tienes dudas sobre tus datos, escríbele a ${LegalDocument.contact}.',
    'Última actualización: ${LegalDocument.updatedAt}.',
  ]),
];
