import 'dart:ui' as ui;
import 'dart:ui' show Color;

import 'package:party_tricks/services/game_engine/board_layout.dart';
import 'package:party_tricks/theme/app_colors.dart';

/// Cada dibujo que pone el código sobre el mapa y que un tema puede
/// cambiar. Los demás (plataformas, tiendas, puentes, decoraciones) los
/// coloca cada mapa en Tiled.
///
/// Todos los temas usan los mismos nombres de archivo, así el código nunca
/// escribe rutas: las arma con la carpeta del tema.
enum ThemeAsset {
  /// Textura que se repite a lo largo del camino entre casillas.
  pathTexture('textura_camino.png'),

  /// Flecha para elegir camino en una bifurcación.
  branchArrow('flecha_bifurcacion.png'),

  startMark('marca_inicio.png'),
  positiveMark('marca_positiva.png'),
  negativeMark('marca_negativa.png'),
  specialMark('marca_especial.png'),
  shopMark('marca_tienda.png'),

  /// Se dibuja debajo de la marca de la casilla en las bifurcaciones.
  forkMark('marca_bifurcacion.png'),

  /// El diamante del mapa y las trampas. Sin dibujo, se usa un ícono.
  diamond('diamante.png'),
  trap('trampa.png');

  const ThemeAsset(this.fileName);

  final String fileName;

  /// La marca de una casilla de tipo [type].
  static ThemeAsset markFor(TileType type) => switch (type) {
    TileType.start => startMark,
    TileType.positive => positiveMark,
    TileType.negative => negativeMark,
    TileType.special => specialMark,
    TileType.shop => shopMark,
  };
}

/// Colores que el código usa al dibujar el mapa.
class MapThemeColors {
  const MapThemeColors({
    this.ground = AppColors.tilePositive,
    this.path = AppColors.mapPath,
    this.arrowBackground = AppColors.boardPanel,
    this.arrowIcon = AppColors.settingsAccent,
    this.diamond = AppColors.diamond,
    this.accent = AppColors.authAccent,
  });

  /// Lo que se ve si el fondo no carga.
  final Color ground;

  /// El camino, si no hay textura.
  final Color path;

  final Color arrowBackground;

  /// La flecha, si no hay dibujo.
  final Color arrowIcon;

  /// El diamante, si no hay dibujo.
  final Color diamond;

  /// Color del mapa en el selector.
  final Color accent;
}

/// Cómo se ven las piezas que pone el código en un mapa. Varios mapas
/// pueden usar el mismo tema.
///
/// Para agregar un tema: crear la carpeta `assets/themes/<id>/` con los
/// dibujos que cambian (los nombres de [ThemeAsset]), agregarla a
/// `pubspec.yaml` y registrar el tema en [MapThemeCatalog]. Lo que no
/// esté en la carpeta se toma del tema clásico.
class MapTheme {
  const MapTheme({
    required this.id,
    required this.directory,
    this.colors = const MapThemeColors(),
    this.pathWidth = defaultPathWidth,
  });

  /// Cerca de la mitad del ancho de una plataforma.
  static const defaultPathWidth = 160.0;

  final String id;

  /// Carpeta con los dibujos del tema.
  final String directory;

  final MapThemeColors colors;

  /// Ancho del camino entre casillas, en píxeles del mundo.
  final double pathWidth;

  String pathOf(ThemeAsset asset) => '$directory/${asset.fileName}';
}

/// Los temas del juego.
class MapThemeCatalog {
  const MapThemeCatalog._();

  /// Piedra y pasto: el del primer mapa. Sus dibujos están junto a las
  /// demás piezas del mapa. También es el respaldo de los otros temas.
  static const classic = MapTheme(
    id: 'clasico',
    directory: 'assets/images/mapa/piezas',
  );

  static const all = [classic];

  /// Donde van los temas nuevos: `assets/themes/<id>/`.
  static const themesDirectory = 'assets/themes';
}

/// Un dibujo que el tema no tiene: se usó el de [fallback], o ninguno si
/// es null.
class ThemeFallback {
  const ThemeFallback(this.asset, this.fallback);

  final ThemeAsset asset;
  final String? fallback;
}

/// Un tema con sus dibujos ya buscados: cada [ThemeAsset] apunta a un
/// archivo que existe, o no está si nadie lo tiene. Así los widgets nunca
/// piden archivos que faltan.
class ResolvedMapTheme {
  const ResolvedMapTheme({
    required this.theme,
    required this.assets,
    this.fallbacks = const [],
  });

  final MapTheme theme;
  final Map<ThemeAsset, String> assets;

  /// Lo que se tomó del tema clásico o se dejó sin dibujo.
  final List<ThemeFallback> fallbacks;

  MapThemeColors get colors => theme.colors;

  String? operator [](ThemeAsset asset) => assets[asset];

  String? markFor(TileType type) => assets[ThemeAsset.markFor(type)];

  /// Una línea para el log, o null si al tema no le falta nada.
  String? describeFallbacks() {
    if (fallbacks.isEmpty) return null;
    final replaced = [
      for (final f in fallbacks)
        if (f.fallback != null) f.asset.fileName,
    ];
    final missing = [
      for (final f in fallbacks)
        if (f.fallback == null) f.asset.fileName,
    ];
    return [
      'Tema ${theme.id}:',
      if (replaced.isNotEmpty)
        'faltan ${replaced.join(', ')}; se usan los del tema clásico.',
      if (missing.isNotEmpty)
        'sin ${missing.join(', ')} (ningún tema los tiene); se dibuja lo '
            'de siempre.',
    ].join(' ');
  }
}

/// Un tema listo para dibujar: sus dibujos y la textura del camino ya
/// cargada (null si no hay; entonces el camino se pinta de un color).
class LoadedMapTheme {
  const LoadedMapTheme(this.resolved, {this.pathTexture});

  final ResolvedMapTheme resolved;
  final ui.Image? pathTexture;

  MapTheme get theme => resolved.theme;
  MapThemeColors get colors => resolved.colors;
}

/// Busca los dibujos de [theme] entre [available] (los assets de la app).
/// Lo que falta se toma de [fallback]; si tampoco está, se deja sin dibujo
/// y el código usa su respaldo (un ícono o un color).
ResolvedMapTheme resolveTheme(
  MapTheme theme,
  Set<String> available, {
  MapTheme fallback = MapThemeCatalog.classic,
}) {
  final assets = <ThemeAsset, String>{};
  final fallbacks = <ThemeFallback>[];
  final isFallback = theme.id == fallback.id;
  for (final asset in ThemeAsset.values) {
    final own = theme.pathOf(asset);
    if (available.contains(own)) {
      assets[asset] = own;
      continue;
    }
    final other = fallback.pathOf(asset);
    final found = !isFallback && available.contains(other);
    if (found) assets[asset] = other;
    // Al clásico le pueden faltar dibujos opcionales (no tiene moneda ni
    // diamante): no se avisa. A los demás temas, sí.
    if (!isFallback) fallbacks.add(ThemeFallback(asset, found ? other : null));
  }
  return ResolvedMapTheme(theme: theme, assets: assets, fallbacks: fallbacks);
}

/// Problemas de un tema: archivos en su carpeta que parecen dibujos del
/// tema pero con otro nombre (por ejemplo `marca_especal.png`), que la app
/// nunca usaría. Vacío si todo está bien.
List<String> validateTheme(MapTheme theme, Set<String> available) {
  final known = {for (final asset in ThemeAsset.values) asset.fileName};
  final prefixes = {for (final name in known) name.split(RegExp('[_.]')).first};
  final problems = <String>[];
  if (!theme.directory.startsWith('assets/')) {
    problems.add('La carpeta ${theme.directory} está fuera de assets/.');
  }
  final inFolder = available.where(
    (path) => path.startsWith('${theme.directory}/'),
  );
  for (final path in inFolder) {
    final name = path.substring(theme.directory.length + 1);
    if (name.contains('/') || known.contains(name)) continue;
    if (prefixes.contains(name.split(RegExp('[_.]')).first)) {
      problems.add(
        'Tema ${theme.id}: "$name" no es un dibujo del tema; ¿quisiste '
        'decir uno de ${known.join(', ')}?',
      );
    }
  }
  return problems;
}
