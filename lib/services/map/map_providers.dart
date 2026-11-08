import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:party_tricks/models/map/board_map.dart';
import 'package:party_tricks/services/map/map_catalog.dart';
import 'package:party_tricks/services/map/map_theme.dart';
import 'package:party_tricks/services/map/tiled_map_parser.dart';

/// El mapa con ese id (el `mapId` de la partida). Lanza
/// [UnknownMapException] si esta versión de la app no lo tiene.
final mapDefinitionProvider = Provider.family<MapDefinition, String>(
  (ref, mapId) => MapCatalog.require(mapId),
);

/// El mapa dibujado, leído de su archivo de Tiled.
final boardMapProvider = FutureProvider.family<BoardMap, String>((
  ref,
  mapId,
) async {
  final definition = ref.watch(mapDefinitionProvider(mapId));
  final text = await rootBundle.loadString(definition.tiledMap);
  return const TiledMapParser().parse(
    jsonDecode(text) as Map<String, dynamic>,
    mapDir: definition.assetDirectory,
    background: definition.background,
  );
});

/// El tema del mapa con ese id, con sus dibujos ya buscados y la textura
/// del camino cargada. Lo que le falta al tema se toma del clásico y se
/// avisa una sola vez en el log.
final mapThemeProvider = FutureProvider.family<LoadedMapTheme, String>((
  ref,
  mapId,
) async {
  final theme = ref.watch(mapDefinitionProvider(mapId)).theme;
  final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
  final resolved = resolveTheme(theme, manifest.listAssets().toSet());
  if (resolved.describeFallbacks() case final message?) debugPrint(message);
  final texturePath = resolved[ThemeAsset.pathTexture];
  final texture = texturePath == null ? null : await _decode(texturePath);
  ref.onDispose(() => texture?.dispose());
  return LoadedMapTheme(resolved, pathTexture: texture);
});

Future<ui.Image?> _decode(String asset) async {
  try {
    final data = await rootBundle.load(asset);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    return (await codec.getNextFrame()).image;
  } on Exception catch (error) {
    // Una textura dañada no rompe la partida: el camino se pinta de color.
    debugPrint('Mapa: no se pudo cargar $asset ($error)');
    return null;
  }
}
