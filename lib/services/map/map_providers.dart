import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:party_tricks/models/map/board_map.dart';
import 'package:party_tricks/services/map/map_assets.dart';
import 'package:party_tricks/services/map/tiled_map_parser.dart';

/// El mapa dibujado que se juega, leído del archivo de Tiled.
final boardMapProvider = FutureProvider<BoardMap>((ref) async {
  const dir = MapAssets.firstMap;
  final text = await rootBundle.loadString('$dir/mapa.tmj');
  return const TiledMapParser().parse(
    jsonDecode(text) as Map<String, dynamic>,
    mapDir: dir,
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
