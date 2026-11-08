import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:party_tricks/models/map/board_map.dart';
import 'package:party_tricks/services/map/map_assets.dart';
import 'package:party_tricks/services/map/map_catalog.dart';
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

/// La textura del caminito, lista para pintarla repetida.
final pathTextureProvider = FutureProvider<ui.Image>((ref) async {
  final data = await rootBundle.load(MapAssets.pathTexture);
  final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
  final image = (await codec.getNextFrame()).image;
  ref.onDispose(image.dispose);
  return image;
});
