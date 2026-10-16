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
  // Marcadores de posición (hasta tener el arte final)
  // ---------------------------------------------------------------------------

  static const Color placeholderIcon = Color(0xB3FFFFFF);
}