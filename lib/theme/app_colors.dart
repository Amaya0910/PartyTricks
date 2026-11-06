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

  /// Borde punteado celeste de cada artículo de la lista.
  static const Color shopItemBorder = Color(0xFFA9D3E6);

  /// Fondo celeste muy claro detrás de la lista de artículos.
  static const Color shopListBackground = Color(0xFFEAF4F9);

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

  // ---------------------------------------------------------------------------
  // Personaje y dado (provisionales hasta tener las hojas de animación)
  // ---------------------------------------------------------------------------

  /// Piel de la cara y las manos.
  static const Color characterSkin = Color(0xFFFFD9B8);

  /// Contorno negro del personaje (arte_imagenes.md, sección 1).
  static const Color characterOutline = Color(0xFF1A1A1A);

  /// Los 40 tonos de piel que se eligen en el Vestuario: 20 reales, de claro
  /// a oscuro, y 20 fantasiosos.
  /// En Firestore se guarda solo la posición en esta lista (ver SkinTone).
  static const List<Color> skinTones = [
    Color(0xFFFFF1E6),
    Color(0xFFFCE3D0),
    Color(0xFFF8D5BE),
    Color(0xFFF3C6A5),
    Color(0xFFEDB98A),
    Color(0xFFE5A97A),
    Color(0xFFD99A6C),
    Color(0xFFCB8B5C),
    Color(0xFFBE7B4F),
    Color(0xFFB06F45),
    Color(0xFFA0623C),
    Color(0xFF8F5535),
    Color(0xFF7E4A2F),
    Color(0xFF6F402A),
    Color(0xFF603624),
    Color(0xFF532E20),
    Color(0xFF47271C),
    Color(0xFF3D2219),
    Color(0xFF331C15),
    Color(0xFF2A1712),
    // Del 21 al 40: colores fantasiosos, nada realistas.
    Color(0xFF000000), // negro puro
    Color(0xFFFFFFFF), // blanco puro
    Color(0xFF8E9AA6), // gris
    Color(0xFFD50000), // rojo
    Color(0xFFFF6D00), // naranja
    Color(0xFFFFD600), // amarillo
    Color(0xFFAEEA00), // lima
    Color(0xFF00C853), // verde
    Color(0xFF00BFA5), // verde azulado
    Color(0xFF00E5FF), // turquesa
    Color(0xFF29B6F6), // celeste
    Color(0xFF2962FF), // azul
    Color(0xFF1A237E), // azul noche
    Color(0xFF651FFF), // violeta
    Color(0xFFAA00FF), // morado
    Color(0xFFE040FB), // orquídea
    Color(0xFFFF4081), // rosa chicle
    Color(0xFFF8BBD0), // rosa pastel
    Color(0xFFB9F6CA), // menta pastel
    Color(0xFFFFD180), // durazno pastel
  ];

  /// Colores de fondo de la foto de perfil (la cabeza del personaje). En
  /// Firestore se guarda solo la posición (ver AvatarColor).
  static const List<Color> avatarColors = [
    Color(0xFFA5D3C5),
    Color(0xFF8DDDFF),
    Color(0xFF3F9FD8),
    Color(0xFF1F3A93),
    Color(0xFF8A5CE0),
    Color(0xFFE040FB),
    Color(0xFFE0589B),
    Color(0xFFFF8A80),
    Color(0xFFD50000),
    Color(0xFFFF8A3D),
    Color(0xFFF2C230),
    Color(0xFFAEEA00),
    Color(0xFF2E9E6B),
    Color(0xFF8B5A2B),
    Color(0xFF8E9AA6),
    Color(0xFF2B2B2B),
  ];

  /// Colores de la rareza de los cosméticos (común a legendario).
  static const Color rarityCommon = Color(0xFF8FA05A);
  static const Color rarityUncommon = Color(0xFF3F9FD8);
  static const Color rarityRare = Color(0xFF8A5CE0);
  static const Color rarityEpic = Color(0xFFE0589B);
  static const Color rarityLegendary = Color(0xFFF2A81D);

  /// Los 20 colores de ojos que se eligen en el Vestuario. Tiñen la parte
  /// blanca de la línea del ojo (ver EyeColor); el primero, blanco, deja el
  /// dibujo original. En Firestore se guarda solo la posición.
  static const List<Color> eyeColors = [
    Color(0xFFFFFFFF), // original
    Color(0xFFB8C4CC),
    Color(0xFF77ABD5),
    Color(0xFF3F7FBF),
    Color(0xFF1F3A93),
    Color(0xFF4FC3C8),
    Color(0xFF2E9E6B),
    Color(0xFF8DBF4A),
    Color(0xFF6B7A2E),
    Color(0xFFF2C230),
    Color(0xFFD99A2B),
    Color(0xFFE0702A),
    Color(0xFF8B5A2B),
    Color(0xFF4A2C1D),
    Color(0xFFAA0033),
    Color(0xFF780422),
    Color(0xFFE85A9B),
    Color(0xFFAA00A7),
    Color(0xFF7A3FC2),
    Color(0xFF2B2B2B),
  ];

  /// Sombra en el piso y rubor de las mejillas.
  static const Color characterShadow = Color(0x40000000);
  static const Color characterBlush = Color(0x55FF7B7B);

  /// Fondo oscuro detrás del dado mientras rueda.
  static const Color diceScrim = Color(0x33000000);

  // ---------------------------------------------------------------------------
  // Minijuegos (reutilizan colores que ya existían)
  // ---------------------------------------------------------------------------

  /// Tarjeta del minijuego y del resultado.
  static const Color minigamePanel = boardPanel;

  /// Reacción: "Prepárate" (no toques) y "¡YA!" (toca).
  static const Color reactionWait = authError;
  static const Color reactionGo = accept;

  /// Botones para jugar ("¡Ya!", inflar).
  static const Color minigameButton = authAccent;

  /// Globo Bomba: el globo y los que ya reventaron.
  static const Color balloon = authError;
  static const Color minigameOut = authError;

  /// Quien ganó el minijuego.
  static const Color minigameWinner = coin;

  /// Cabecera, borde y botones de cada minijuego.
  static const Color minigameStopwatch = authAccent;
  static const Color minigameReaction = activeButton;
  static const Color minigameBalloon = chestDiamondStrong;

  /// Fondo suave de los recuadros de ayuda y de las píldoras.
  static const Color minigameSoft = Color(0xFFF2F8FC);

  /// Pista vacía del reloj y de la barra de tiempo.
  static const Color minigameTrack = authField;

  /// Brillo del globo y de los botones.
  static const Color minigameShine = Color(0x8CFFFFFF);

  /// Franja dorada del resultado y fila de quien ganó.
  static const Color minigameWinnerSoft = pillBackground;
}
