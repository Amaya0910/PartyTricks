import 'package:flutter/material.dart';
import 'package:party_tricks/services/map/map_catalog.dart';
import 'package:party_tricks/theme/app_colors.dart';

/// La vista previa de un mapa (`preview.png` de su carpeta). Si falta,
/// muestra un recuadro con el nombre para que la pantalla no se rompa.
class MapPreviewImage extends StatelessWidget {
  const MapPreviewImage({super.key, required this.map, this.decodeWidth});

  final MapDefinition map;

  /// Ancho al que se decodifica la imagen, para no guardar en memoria más
  /// de lo que se ve (las miniaturas no necesitan la imagen completa).
  final int? decodeWidth;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      map.previewImage,
      fit: BoxFit.cover,
      alignment: Alignment.topCenter,
      cacheWidth: decodeWidth,
      errorBuilder: (_, _, _) => _Placeholder(name: map.name),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    // Se achica para caber también en las miniaturas pequeñas.
    return ColoredBox(
      color: AppColors.tilePositive,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.map, color: AppColors.placeholderIcon, size: 40),
              Text(
                name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
