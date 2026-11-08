import 'dart:ui' show Color;

import 'package:party_tricks/models/app_protocol.dart';
import 'package:party_tricks/services/map/map_catalog.dart';
import 'package:party_tricks/services/map/map_theme.dart';

import '../game_engine/test_board.dart';

/// Tema de prueba con su propio color; sus dibujos no existen.
const candyTheme = MapTheme(
  id: 'dulce_prueba',
  directory: 'assets/themes/dulce_prueba',
  colors: MapThemeColors(accent: Color(0xFFFF77AA)),
);

/// Mapas de mentira para probar la lista con muchos mapas. No tienen
/// vista previa, así que se ve el recuadro de reemplazo. Los pares usan
/// [candyTheme] y piden el protocolo de esta versión.
List<MapDefinition> fakeMaps(int count) => [
  MapCatalog.mapa01,
  for (var i = 2; i <= count; i++)
    MapDefinition(
      id: 'mapa_prueba_$i',
      name: 'Prueba $i',
      shortDescription: 'Mapa de prueba $i',
      assetDirectory: 'assets/maps/mapa_prueba_$i',
      buildBoard: buildTestBoard,
      minProtocol: i.isEven ? AppProtocol.current : ProtocolLevel.base,
      theme: i.isEven ? candyTheme : MapThemeCatalog.classic,
    ),
];
