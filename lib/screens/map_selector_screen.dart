import 'package:flutter/material.dart';
import 'package:party_tricks/services/map/map_catalog.dart';
import 'package:party_tricks/theme/app_colors.dart';
import 'package:party_tricks/widgets/map/map_preview_image.dart';

/// Pantalla para elegir el mapa de la sala. Devuelve el id del mapa elegido
/// o null si se vuelve sin elegir.
///
/// - En el celular: el mapa elegido arriba, grande, y los demás en una fila
///   que se desliza.
/// - En la tablet (o el celular acostado): el detalle a la izquierda y la
///   lista a la derecha.
///
/// Sirve para cualquier cantidad de mapas: la lista se desliza.
class MapSelectorScreen extends StatefulWidget {
  const MapSelectorScreen({
    super.key,
    required this.selectedId,
    required this.rounds,
    required this.players,
    this.maps = MapCatalog.all,
  });

  final String selectedId;

  /// Las de la sala que se está armando, para estimar la duración.
  final int rounds;
  final int players;
  final List<MapDefinition> maps;

  /// Ancho desde el que se muestran el detalle y la lista lado a lado.
  static const wideLayout = 720.0;

  static Future<String?> show(
    BuildContext context, {
    required String selectedId,
    required int rounds,
    required int players,
    List<MapDefinition> maps = MapCatalog.all,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MapSelectorScreen(
          selectedId: selectedId,
          rounds: rounds,
          players: players,
          maps: maps,
        ),
      ),
    );
  }

  @override
  State<MapSelectorScreen> createState() => _MapSelectorScreenState();
}

class _MapSelectorScreenState extends State<MapSelectorScreen> {
  late MapDefinition _selected = widget.maps.firstWhere(
    (map) => map.id == widget.selectedId,
    orElse: () => widget.maps.first,
  );

  void _choose() => Navigator.of(context).pop(_selected.id);

  @override
  Widget build(BuildContext context) {
    final detail = _MapDetail(
      map: _selected,
      rounds: widget.rounds,
      players: widget.players,
    );
    final accent = _selected.theme.colors.accent;
    return Scaffold(
      backgroundColor: AppColors.screenBackground,
      appBar: AppBar(
        backgroundColor: accent,
        foregroundColor: AppColors.white,
        title: const Text(
          'Elige el mapa',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth >= MapSelectorScreen.wideLayout) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: detail),
                  SizedBox(
                    width: 300,
                    child: _MapList(
                      maps: widget.maps,
                      selected: _selected,
                      direction: Axis.vertical,
                      onSelect: (map) => setState(() => _selected = map),
                    ),
                  ),
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: detail),
                if (widget.maps.length > 1)
                  SizedBox(
                    height: 150,
                    child: _MapList(
                      maps: widget.maps,
                      selected: _selected,
                      direction: Axis.horizontal,
                      onSelect: (map) => setState(() => _selected = map),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: SizedBox(
            height: 48,
            child: FilledButton(
              key: const Key('choose-map-button'),
              style: FilledButton.styleFrom(
                backgroundColor: accent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: _choose,
              child: Text(
                'Jugar en ${_selected.name}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// La vista previa grande y la información del mapa.
class _MapDetail extends StatelessWidget {
  const _MapDetail({
    required this.map,
    required this.rounds,
    required this.players,
  });

  final MapDefinition map;
  final int rounds;
  final int players;

  @override
  Widget build(BuildContext context) {
    final summary = map.summary;
    final recommended = map.recommendedPlayers;
    final minutes = map.estimatedMinutes(rounds: rounds, players: players);
    return LayoutBuilder(
      builder: (context, constraints) {
        // La vista previa ocupa hasta la mitad del alto, sin pasarse del
        // ancho; el resto se desplaza si no cabe.
        final previewHeight = (constraints.maxHeight * 0.55)
            .clamp(180.0, 520.0)
            .toDouble();
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: previewHeight,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: DecoratedBox(
                    position: DecorationPosition.foreground,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.white, width: 3),
                    ),
                    child: MapPreviewImage(key: ValueKey(map.id), map: map),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                map.name,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.white,
                  shadows: [Shadow(color: AppColors.pillShadow, blurRadius: 4)],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                map.description,
                style: const TextStyle(fontSize: 15, color: AppColors.authText),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _InfoChip(
                    icon: Icons.grid_view_rounded,
                    label: '${summary.tiles} casillas · ${summary.size.label}',
                  ),
                  _InfoChip(
                    icon: Icons.alt_route,
                    label: summary.forks == 1
                        ? '1 atajo'
                        : '${summary.forks} atajos',
                  ),
                  _InfoChip(
                    icon: Icons.storefront,
                    label: summary.shops == 1
                        ? '1 tienda'
                        : '${summary.shops} tiendas',
                  ),
                  _InfoChip(
                    icon: Icons.timer_outlined,
                    label: '≈ $minutes min ($rounds rondas)',
                  ),
                  _InfoChip(
                    icon: Icons.group,
                    label: '${recommended.min}–${recommended.max} jugadores',
                  ),
                  _ProtocolChip(map: map),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label, this.color});

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final color = this.color ?? AppColors.statsDarkBlue;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          // En pantallas angostas el texto largo baja de línea.
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Si los jugadores con versiones viejas de la app pueden entrar.
class _ProtocolChip extends StatelessWidget {
  const _ProtocolChip({required this.map});

  final MapDefinition map;

  @override
  Widget build(BuildContext context) {
    return map.playableByAllVersions
        ? const _InfoChip(
            icon: Icons.verified,
            label: 'Todas las versiones',
            color: AppColors.switchGreenIcon,
          )
        : _InfoChip(
            icon: Icons.system_update,
            label: 'Requiere la app actualizada (protocolo ${map.minProtocol})',
            color: AppColors.coin,
          );
  }
}

/// Los mapas para elegir, en una fila (celular) o una columna (tablet).
class _MapList extends StatelessWidget {
  const _MapList({
    required this.maps,
    required this.selected,
    required this.direction,
    required this.onSelect,
  });

  final List<MapDefinition> maps;
  final MapDefinition selected;
  final Axis direction;
  final ValueChanged<MapDefinition> onSelect;

  @override
  Widget build(BuildContext context) {
    final horizontal = direction == Axis.horizontal;
    return ListView.separated(
      key: const Key('map-list'),
      scrollDirection: direction,
      padding: horizontal
          ? const EdgeInsets.fromLTRB(16, 0, 16, 8)
          : const EdgeInsets.fromLTRB(0, 16, 16, 16),
      itemCount: maps.length,
      separatorBuilder: (_, _) => const SizedBox(width: 12, height: 12),
      itemBuilder: (context, index) {
        final map = maps[index];
        final thumb = _MapThumb(
          map: map,
          selected: map.id == selected.id,
          onTap: () => onSelect(map),
        );
        return horizontal
            ? SizedBox(width: 110, child: thumb)
            : SizedBox(height: 200, child: thumb);
      },
    );
  }
}

class _MapThumb extends StatelessWidget {
  const _MapThumb({
    required this.map,
    required this.selected,
    required this.onTap,
  });

  final MapDefinition map;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      label: map.name,
      child: GestureDetector(
        key: ValueKey('map-thumb-${map.id}'),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? map.theme.colors.accent : AppColors.white,
              width: selected ? 4 : 2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  child: MapPreviewImage(map: map, decodeWidth: 240),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Text(
                  map.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.authText,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
