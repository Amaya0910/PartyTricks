import 'package:flutter/material.dart';

/// Colores del mockup de Figma. Es el único lugar donde se definen.
class AppColors {
  AppColors._();

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
  // Menú de "Jugar" y barra de carga
  // ---------------------------------------------------------------------------

  static const Color menuButton = Color(0xFF63A8DC);
  static const Color progressText = Color(0xFFFFFFFF);

  /// Se ve si falta la imagen de la pantalla de carga.
  static const Color loadingFallback = Color(0xFF0B2A5B);

  // ---------------------------------------------------------------------------
  // Inicio de sesión y registro
  // (el fondo azul claro es [screenBackground])
  // ---------------------------------------------------------------------------

  /// Azul de la cabecera, el borde y el botón de la tarjeta.
  static const Color authAccent = Color(0xFF63A9DB);

  /// Gris claro de los campos de texto.
  static const Color authField = Color(0xFFE4E4E4);

  static const Color authCardBackground = Color(0xFFFFFFFF);

  /// Texto sobre el azul (título de la tarjeta y botón).
  static const Color authOnAccent = Color(0xFFFFFFFF);

  /// Texto escrito en los campos y enlace de cambio de tarjeta.
  static const Color authText = Color(0xFF4A4A4A);

  /// Texto de ayuda dentro de los campos vacíos.
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
  static const Color tileBorder = Color(0xFFFFFFFF);
  static const Color boardPanel = Color(0xE6FFFFFF);

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

}

