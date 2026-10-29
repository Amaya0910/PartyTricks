import 'package:flutter/material.dart';

/// Colores del mockup de Figma. Es el único lugar donde se definen.
class AppColors {
  AppColors._();

  // ---------------------------------------------------------------------------
  // Colores compartidos
  // ---------------------------------------------------------------------------

  /// Blanco: fondo de tarjetas, texto sobre azul y bordes claros.
  static const Color white = Color(0xFFFFFFFF);

  /// Azul principal de la app: cabeceras, bordes, botones y controles.
  static const Color authAccent = Color(0xFF63A9DB);

  // ---------------------------------------------------------------------------
  // Barra de navegación y fondo
  // ---------------------------------------------------------------------------

  /// Botón activo de la barra de navegación.
  static const Color activeButton = Color(0xFF74B275);

  /// Botón inactivo y fondo de la barra de navegación.
  static const Color inactiveButton = Color(0xFF558455);

  /// Texto e íconos de la barra de navegación.
  static const Color navigationContent = Color(0xFF243824);

  /// Color principal del dibujo de fondo (se usa mientras no esté la imagen).
  static const Color screenBackground = Color(0xFF9BCCE1);

  // ---------------------------------------------------------------------------
  // Azules del diamante (botón "Jugar" y barra de carga)
  // ---------------------------------------------------------------------------

  /// Barra interior (efecto líquido) y fondo del botón "Jugar".
  static const Color blueLight = Color(0xFF8DDDFF);

  /// Barra exterior y color del diamante.
  static const Color blueMain = Color(0xFF45C7FF);

  /// Trazo de la barra y borde/texto del botón "Jugar".
  static const Color blueStrong = Color(0xFF139BFF);

  // ---------------------------------------------------------------------------
  // Cabecera del jugador
  // ---------------------------------------------------------------------------

  static const Color headerBackground = Color(0xB36AA7C9);
  static const Color headerBorder = Color(0xFF1B6CA8);
  static const Color headerPanel = Color(0x3DFFFFFF);
  static const Color avatarBackground = Color(0xFFA5D3C5);

  // ---------------------------------------------------------------------------
  // Monedas y diamantes
  // ---------------------------------------------------------------------------

  static const Color pillBackground = Color(0xFFF7FFC2);
  static const Color coin = Color(0xFFFF9800);
  static const Color diamond = blueMain;

  // ---------------------------------------------------------------------------
  // Barra de carga
  // ---------------------------------------------------------------------------

  /// Se ve si falta la imagen de la pantalla de carga.
  static const Color loadingFallback = Color(0xFF0B2A5B);

  // ---------------------------------------------------------------------------
  // Inicio de sesión y registro
  // (el fondo azul claro es [screenBackground])
  // ---------------------------------------------------------------------------

  /// Gris claro de los campos de texto.
  static const Color authField = Color(0xFFE4E4E4);

  /// Texto escrito en los campos y enlace de cambio de tarjeta.
  static const Color authText = Color(0xFF4A4A4A);

  /// Texto de ayuda: campos vacíos y subtítulos grises.
  static const Color authHint = Color(0xFF6E6E6E);

  static const Color authError = Color(0xFFD32F2F);

  /// Sombra azulada de la tarjeta.
  static const Color authShadow = Color(0x6663A9DB);

  // ---------------------------------------------------------------------------
  // Marcadores de posición (hasta tener el arte final)
  // ---------------------------------------------------------------------------

  static const Color placeholderIcon = Color(0xB3FFFFFF);

  // ---------------------------------------------------------------------------
  // Tablero (provisional hasta tener el dibujo del tablero)
  // ---------------------------------------------------------------------------

  static const Color tileStart = blueStrong;
  static const Color tilePositive = Color(0xFF66BB6A);
  static const Color tileNegative = Color(0xFFE57373);
  static const Color tileSpecial = Color(0xFFBA68C8);
  static const Color tileShop = coin;
  static const Color boardPanel = Color(0xE6FFFFFF);

  /// Trampa puesta en el tablero de cuadritos.
  static const Color trap = Color(0xFF424242);

  // ---------------------------------------------------------------------------
  // Resultados
  // ---------------------------------------------------------------------------

  /// Medallas del 1.º, 2.º y 3.º puesto.
  static const Color medalGold = Color(0xFFFFC107);
  static const Color medalSilver = Color(0xFFB0BEC5);
  static const Color medalBronze = Color(0xFFCD7F32);

  /// Fondo de tu fila en la clasificación.
  static const Color resultsMine = Color(0x3345C7FF);

  /// Color de cada jugador, en el orden de turnos.
  static const List<Color> players = [
    Color(0xFFD32F2F),
    Color(0xFF1976D2),
    Color(0xFF388E3C),
    Color(0xFFFBC02D),
    Color(0xFF7B1FA2),
    Color(0xFFF57C00),
  ];

  // ---------------------------------------------------------------------------
  // Sala de espera
  // ---------------------------------------------------------------------------

  /// Fondo gris azulado del recuadro del código.
  static const Color lobbyCodePanel = Color(0xFFB8C7D1);

  /// Borde de los espacios de jugador.
  static const Color slotBorder = Color(0xFF6FA394);

  // ---------------------------------------------------------------------------
  // Diálogos
  // ---------------------------------------------------------------------------

  /// Velo suave detrás de los diálogos (el desenfoque hace el resto).
  static const Color dialogBarrier = Color(0x1F000000);

  // ---------------------------------------------------------------------------
  // Crear sala ("Alista tu party")
  // ---------------------------------------------------------------------------

  /// Parte sin rellenar de los deslizadores y fondo del interruptor.
  static const Color sliderInactive = Color(0xFFDADADA);
  static const Color switchBorder = Color(0xFFBDBDBD);

  /// Interruptor en modo privado (verde) y su ícono.
  static const Color switchGreen = Color(0xFF86CB87);
  static const Color switchGreenIcon = Color(0xFF3E7D40);

  /// Sombra suave bajo las etiquetas azules.
  static const Color pillShadow = Color(0x40000000);

  // ---------------------------------------------------------------------------
  // Vestuario
  // ---------------------------------------------------------------------------

  /// Fondo gris de cada categoría en la barra de pestañas.
  static const Color wardrobeChip = Color(0xFFD9D9D9);

  /// Íconos, textos y bordes punteados de los cosméticos.
  static const Color wardrobeInk = Color(0xFF000000);

  // ---------------------------------------------------------------------------
  // Tienda
  // ---------------------------------------------------------------------------

  /// Franja "COFRES".
  static const Color shopBand = Color(0xFFD6EAB9);

  /// De cada cofre: `Card` para fondos y `Strong` para bordes, cabeceras
  /// y textos.
  static const Color chestBasicCard = Color(0xFFDDFF8F);
  static const Color chestBasicStrong = Color(0xFF8FA05A);
  static const Color chestPartyCard = Color(0xFFF5D391);
  static const Color chestPartyStrong = Color(0xFFB09868);
  static const Color chestDiamondCard = Color(0xFFC688FF);
  static const Color chestDiamondStrong = Color(0xFF8E62B6);

  // ---------------------------------------------------------------------------
  // Estadísticas
  // ---------------------------------------------------------------------------

  /// Cabecera y borde de las tarjetas de la pantalla Stats. Se repiten en
  /// orden: azul, azul oscuro y morado. Solo el azul oscuro es nuevo; los
  /// otros reutilizan colores que ya existían.
  static const Color statsBlue = authAccent;
  static const Color statsDarkBlue = Color(0xFF5381A5);
  static const Color statsPurple = chestDiamondStrong;

  /// Etiquetas y números de las filas.
  static const Color statsText = wardrobeInk;

  // ---------------------------------------------------------------------------
  // Amigos y chat (todos reutilizan colores que ya existían)
  // ---------------------------------------------------------------------------

  /// Borde de la tarjeta "Tus amigos" y del chat.
  static const Color friendsBorder = statsDarkBlue;

  /// Cabecera "Tus amigos", burbujas propias y botón "+".
  static const Color friendsAccent = authAccent;

  /// Cabecera del chat y recuadro de la foto de cada amigo.
  static const Color chatHeader = avatarBackground;

  /// Burbujas del amigo y campo para escribir.
  static const Color chatField = authField;

  /// Punto de mensajes sin leer.
  static const Color unreadDot = blueStrong;

  /// Botón Aceptar y Rechazar de las solicitudes.
  static const Color accept = activeButton;
  static const Color reject = authError;

  // ---------------------------------------------------------------------------
  // Ajustes (todos reutilizan colores que ya existían)
  // ---------------------------------------------------------------------------

  /// Cabeceras moradas de las tarjetas (Cuenta, Preferencias, Más opciones).
  static const Color settingsAccent = statsPurple;

  /// Fondo translúcido detrás de las tarjetas.
  static const Color settingsPanel = headerPanel;

  /// Borde de cada fila.
  static const Color settingsRowBorder = authField;

  /// Interruptores encendidos y botón Confirmar.
  static const Color settingsOn = inactiveButton;

  /// Botones Copiar y Recargar del código.
  static const Color settingsCopy = accept;
  static const Color settingsReload = statsDarkBlue;

  /// Cerrar sesión.
  static const Color settingsDanger = authError;
}
