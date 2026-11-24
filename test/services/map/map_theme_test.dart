import 'dart:io';
import 'dart:ui' show Color;

import 'package:flutter_test/flutter_test.dart';
import 'package:party_tricks/services/game_engine/board_layout.dart';
import 'package:party_tricks/services/map/map_catalog.dart';
import 'package:party_tricks/services/map/map_theme.dart';

const _classic = MapThemeCatalog.classic;

/// Un tema de prueba al que solo le dibujaron el camino y una marca.
const _candy = MapTheme(
  id: 'dulce_prueba',
  directory: 'assets/themes/dulce_prueba',
  colors: MapThemeColors(accent: Color(0xFFFF77AA)),
);

/// Los dibujos del tema clásico que existen hoy.
final _classicFiles = {
  for (final asset in const [
    ThemeAsset.pathTexture,
    ThemeAsset.branchArrow,
    ThemeAsset.startMark,
    ThemeAsset.negativeMark,
    ThemeAsset.specialMark,
  ])
    _classic.pathOf(asset),
};

/// Los archivos de una carpeta de assets, como los listaría el manifest.
Set<String> _filesIn(String directory) => {
  for (final entity in Directory(directory).listSync())
    if (entity is File) '$directory/${entity.uri.pathSegments.last}',
};

void main() {
  group('resolveTheme', () {
    test('el clásico usa sus dibujos y no avisa por los opcionales', () {
      final resolved = resolveTheme(_classic, _classicFiles);

      expect(
        resolved.markFor(TileType.negative),
        _classic.pathOf(ThemeAsset.negativeMark),
      );
      expect(
        resolved[ThemeAsset.pathTexture],
        _classic.pathOf(ThemeAsset.pathTexture),
      );
      // No tiene moneda, diamante ni trampa dibujados: se usan los íconos.
      expect(resolved.markFor(TileType.positive), isNull);
      expect(resolved[ThemeAsset.diamond], isNull);
      expect(resolved.fallbacks, isEmpty);
      expect(resolved.describeFallbacks(), isNull);
    });

    test('un tema usa lo suyo y toma lo que le falta del clásico', () {
      final resolved = resolveTheme(_candy, {
        ..._classicFiles,
        _candy.pathOf(ThemeAsset.pathTexture),
        _candy.pathOf(ThemeAsset.specialMark),
      });

      expect(
        resolved[ThemeAsset.pathTexture],
        _candy.pathOf(ThemeAsset.pathTexture),
      );
      expect(
        resolved.markFor(TileType.special),
        _candy.pathOf(ThemeAsset.specialMark),
      );
      // Lo que falta, del clásico.
      expect(
        resolved.markFor(TileType.negative),
        _classic.pathOf(ThemeAsset.negativeMark),
      );
      expect(
        resolved[ThemeAsset.branchArrow],
        _classic.pathOf(ThemeAsset.branchArrow),
      );
      // Lo que nadie tiene, sin dibujo.
      expect(resolved[ThemeAsset.diamond], isNull);
    });

    test('el log dice qué falta y de dónde se tomó, en una sola línea', () {
      final resolved = resolveTheme(_candy, {
        ..._classicFiles,
        _candy.pathOf(ThemeAsset.pathTexture),
      });
      final message = resolved.describeFallbacks()!;

      expect(message, startsWith('Tema dulce_prueba:'));
      expect(message, contains('marca_negativa.png'));
      expect(message, contains('tema clásico'));
      expect(message, contains('sin '));
      expect(message, contains('diamante.png'));
      expect(message, isNot(contains('textura_camino.png')));
      expect(message, isNot(contains('\n')));
    });

    test(
      'sin ningún dibujo, todo queda vacío y el código usa sus respaldos',
      () {
        final resolved = resolveTheme(_candy, const {});

        expect(resolved.assets, isEmpty);
        expect(resolved.fallbacks, hasLength(ThemeAsset.values.length));
        expect(resolved.colors.accent, const Color(0xFFFF77AA));
      },
    );
  });

  test('cada tipo de casilla tiene su marca', () {
    expect(ThemeAsset.markFor(TileType.start), ThemeAsset.startMark);
    expect(ThemeAsset.markFor(TileType.positive), ThemeAsset.positiveMark);
    expect(ThemeAsset.markFor(TileType.negative), ThemeAsset.negativeMark);
    expect(ThemeAsset.markFor(TileType.special), ThemeAsset.specialMark);
    expect(ThemeAsset.markFor(TileType.shop), ThemeAsset.shopMark);
  });

  group('validateTheme', () {
    test('detecta dibujos con el nombre mal escrito', () {
      final problems = validateTheme(_candy, {
        _candy.pathOf(ThemeAsset.pathTexture),
        '${_candy.directory}/marca_especal.png',
        '${_candy.directory}/flecha.png',
      });

      expect(problems, hasLength(2));
      expect(problems.first, contains('marca_especal.png'));
    });

    test('no se queja de otras piezas que comparten la carpeta', () {
      expect(
        validateTheme(_classic, {
          ..._classicFiles,
          '${_classic.directory}/plataforma_01.png',
          '${_classic.directory}/tienda.png',
        }),
        isEmpty,
      );
    });

    test('la carpeta tiene que estar dentro de assets', () {
      const outside = MapTheme(id: 'x', directory: 'imagenes/x');
      expect(validateTheme(outside, const {}), hasLength(1));
    });
  });

  group('catálogo de temas', () {
    test('los ids no se repiten y el clásico es el respaldo', () {
      final ids = [for (final theme in MapThemeCatalog.all) theme.id];
      expect(ids.toSet().length, ids.length);
      expect(MapThemeCatalog.all, contains(MapThemeCatalog.classic));
    });

    test('mapa_01 usa el tema clásico', () {
      expect(MapCatalog.mapa01.theme, same(MapThemeCatalog.classic));
    });

    test('todos los mapas usan temas registrados', () {
      for (final map in MapCatalog.all) {
        expect(MapThemeCatalog.all, contains(map.theme), reason: map.id);
      }
    });

    for (final theme in MapThemeCatalog.all) {
      group(theme.id, () {
        test('su carpeta está en pubspec.yaml', () {
          final pubspec = File('pubspec.yaml').readAsLinesSync();
          expect(
            pubspec.map((line) => line.trim()),
            contains('- ${theme.directory}/'),
          );
        });

        test('sus archivos tienen nombres de dibujos del tema', () {
          final problems = validateTheme(theme, _filesIn(theme.directory));
          expect(problems, isEmpty, reason: problems.join('\n'));
        });

        test('sus dibujos existen y no pasan de 4096 px', () {
          final resolved = resolveTheme(theme, _filesIn(theme.directory));
          if (theme == MapThemeCatalog.classic) {
            // El clásico es el respaldo: tiene que tener lo básico.
            expect(
              resolved.assets.keys,
              containsAll(const [
                ThemeAsset.pathTexture,
                ThemeAsset.branchArrow,
                ThemeAsset.startMark,
                ThemeAsset.negativeMark,
                ThemeAsset.specialMark,
              ]),
            );
          }
          for (final path in resolved.assets.values) {
            final bytes = File(path).readAsBytesSync();
            int read(int at) =>
                bytes[at] << 24 |
                bytes[at + 1] << 16 |
                bytes[at + 2] << 8 |
                bytes[at + 3];
            expect(read(16), lessThanOrEqualTo(4096), reason: path);
            expect(read(20), lessThanOrEqualTo(4096), reason: path);
          }
        });
      });
    }
  });
}
