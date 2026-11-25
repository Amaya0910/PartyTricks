import 'package:flutter/material.dart';
import 'package:party_tricks/services/map/board_summary.dart';
import 'package:party_tricks/services/map/map_catalog.dart';
import 'package:party_tricks/services/map/remote_map_config.dart';
import 'package:party_tricks/theme/app_colors.dart';
import 'package:party_tricks/widgets/fx/party_button.dart';
import 'package:party_tricks/widgets/fx/pop_in.dart';
import 'package:party_tricks/widgets/fx/pressable_scale.dart';
import 'package:party_tricks/widgets/map/map_preview_image.dart';

/// Pantalla para elegir el mapa de la sala. Devuelve el id del mapa elegido
/// o null si se vuelve sin elegir.
///
/// - En el celular: el mapa elegido arriba, grande, y los demás en una fila
///   que se desliza.
/// - En la tablet (o el celular acostado): el detalle a la izquierda y la
///   lista a la derecha.
///
/// Sirve para cualquier cantidad de mapas: la lista se desliza. Solo muestra
/// los que están listos (`MapDefinition.selectable`) y encendidos en
/// Firebase ([remote]).
class MapSelectorScreen extends StatefulWidget {
  const MapSelectorScreen({
    super.key,
    required this.selectedId,
    required this.rounds,
    required this.players,
    required this.remote,
    this.maps = MapCatalog.all,
  });

  final String selectedId;

  /// Las de la sala que se está armando, para estimar la duración.
  final int rounds;
  final int players;
  final List<MapDefinition> maps;

  /// Qué mapas están encendidos desde Firebase.
  final RemoteMapConfig remote;

  /// Ancho desde el que se muestran el detalle y la lista lado a lado.
  static const wideLayout = 720.0;

  static Future<String?> show(
    BuildContext context, {
    required String selectedId,
    required int rounds,
    required int players,
    required RemoteMapConfig remote,
    List<MapDefinition> maps = MapCatalog.all,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MapSelectorScreen(
          selectedId: selectedId,
          rounds: rounds,
          players: players,
          remote: remote,
          maps: maps,
        ),
      ),
    );
  }

  @override
  State<MapSelectorScreen> createState() => _MapSelectorScreenState();
}

class _MapSelectorScreenState extends State<MapSelectorScreen> {
  late final List<MapDefinition> _maps = widget.remote.availableOf(widget.maps);
  late MapDefinition _selected = _maps.firstWhere(
    (map) => map.id == widget.selectedId,
    orElse: () => _maps.first,
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
        title: Text(
          'Elige el mapa',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            shadows: [
              Shadow(
                color: Color.alphaBlend(AppColors.edgeShade, accent),
                offset: const Offset(0, 2),
              ),
            ],
          ),
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
                      maps: _maps,
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
                if (_maps.length > 1)
                  SizedBox(
                    height: 150,
                    child: _MapList(
                      maps: _maps,
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
          // Toma el color del mapa elegido.
          child: PartyButton(
            key: const Key('choose-map-button'),
            label: 'Jugar en ${_selected.name}',
            icon: Icons.play_arrow_rounded,
            color: accent,
            edgeColor: null,
            fontSize: 18,
            onPressed: _choose,
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
              // Al cambiar de mapa, la vista previa entra con un rebote.
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 0.9, end: 1).animate(
                      CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOutBack,
                      ),
                    ),
                    child: child,
                  ),
                ),
                child: Container(
                  key: ValueKey(map.id),
                  height: previewHeight,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Color.alphaBlend(
                          AppColors.edgeShade,
                          map.theme.colors.accent,
                        ),
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: DecoratedBox(
                      position: DecorationPosition.foreground,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.white, width: 3),
                      ),
                      child: MapPreviewImage(map: map),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                map.name,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: AppColors.white,
                  shadows: [
                    Shadow(
                      color: Color.alphaBlend(
                        AppColors.edgeShade,
                        map.theme.colors.accent,
                      ),
                      offset: const Offset(0, 3),
                    ),
                  ],
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
                // Los datos del mapa saltan uno detrás de otro.
                children: [
                  for (final (index, chip) in _chips(
                    map,
                    summary,
                    minutes,
                    recommended,
                  ).indexed)
                    PopIn.staggered(
                      key: ValueKey('${map.id}-$index'),
                      index: index,
                      startScale: 0.6,
                      from: Offset.zero,
                      child: chip,
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _chips(
    MapDefinition map,
    BoardSummary summary,
    int minutes,
    ({int min, int max}) recommended,
  ) => [
    _InfoChip(
      icon: Icons.grid_view_rounded,
      label: '${summary.tiles} casillas · ${summary.size.label}',
    ),
    _InfoChip(
      icon: Icons.alt_route,
      label: summary.forks == 1 ? '1 atajo' : '${summary.forks} atajos',
    ),
    _InfoChip(
      icon: Icons.storefront,
      label: summary.shops == 1 ? '1 tienda' : '${summary.shops} tiendas',
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
  ];
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
        border: Border.all(color: color, width: 1.5),
        boxShadow: [BoxShadow(color: color, offset: const Offset(0, 2))],
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
                fontWeight: FontWeight.w800,
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
      child: PressableScale(
        key: ValueKey('map-thumb-${map.id}'),
        onTap: onTap,
        // El elegido crece y queda con el color de su mapa.
        child: AnimatedScale(
          scale: selected ? 1 : 0.92,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutBack,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected ? map.theme.colors.accent : AppColors.white,
                width: selected ? 4 : 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: selected
                      ? Color.alphaBlend(
                          AppColors.edgeShade,
                          map.theme.colors.accent,
                        )
                      : AppColors.pillShadow,
                  offset: const Offset(0, 4),
                ),
              ],
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 4,
                  ),
                  child: Text(
                    map.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: AppColors.authText,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
