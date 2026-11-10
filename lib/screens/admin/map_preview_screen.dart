import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:party_tricks/controllers/character_look_controller.dart';
import 'package:party_tricks/models/accessory_style.dart';
import 'package:party_tricks/models/character_look.dart';
import 'package:party_tricks/models/hair_style.dart';
import 'package:party_tricks/models/pants_style.dart';
import 'package:party_tricks/models/shirt_style.dart';
import 'package:party_tricks/screens/admin/admin_page.dart';
import 'package:party_tricks/services/game/game_providers.dart';
import 'package:party_tricks/services/game_engine/game_state.dart';
import 'package:party_tricks/services/map/map_providers.dart';
import 'package:party_tricks/widgets/map/board_map_view.dart';
import 'package:party_tricks/widgets/settings_section.dart';

/// Vista previa del mapa con personajes, para el panel de administración.
///
/// Muestra el mapa que se juega con de 1 a 4 personajes de aspectos
/// distintos. Se les puede hacer avanzar casillas para ver cómo caminan
/// (de lado, de espalda cuando suben), cómo se ven quietos y cómo van las
/// curvas del camino. El primero lleva el aspecto del administrador y los
/// demás, aspectos de ejemplo. Nada de lo que se toca aquí se guarda y no
/// se crea ninguna partida.
class MapPreviewScreen extends ConsumerStatefulWidget {
  const MapPreviewScreen({super.key});

  static Route<void> route() =>
      MaterialPageRoute(builder: (_) => const MapPreviewScreen());

  @override
  ConsumerState<MapPreviewScreen> createState() => _MapPreviewScreenState();
}

class _MapPreviewScreenState extends ConsumerState<MapPreviewScreen> {
  static const _maxPlayers = 4;

  /// Cuántas casillas avanza cada botón.
  static const _steps = [1, 3, 6];

  int _count = 3;

  /// Casilla de cada jugador (por posición en la lista).
  final List<int> _positions = [0, 0, 0, 0];

  /// Cuántas veces se ha avanzado, para que cada jugador tome caminos
  /// distintos en las bifurcaciones.
  int _moves = 0;

  /// Los aspectos de ejemplo de los demás jugadores.
  static final List<CharacterLook> _samples = [
    CharacterLook.standard.copyWith(
      shirt: ShirtStyle.shifts8,
      pants: PantsStyle.jeans,
      hair: HairStyle.wild,
    ),
    CharacterLook.standard.copyWith(
      shirt: ShirtStyle.shifts12,
      pants: PantsStyle.tutu,
      hair: HairStyle.pigtails,
      accessory: AccessoryStyle.values.first,
    ),
    CharacterLook.standard.copyWith(
      shirt: ShirtStyle.shifts9,
      pants: PantsStyle.neon,
      hair: HairStyle.clownWig,
    ),
  ];

  static String _idOf(int index) => 'p${index + 1}';

  List<CharacterLook> _looks(CharacterLook mine) => [
    mine,
    for (var i = 1; i < _maxPlayers; i++) _samples[(i - 1) % _samples.length],
  ];

  void _advance(int steps) {
    final board = ref.read(boardProvider);
    setState(() {
      _moves++;
      for (var i = 0; i < _count; i++) {
        // Cada jugador avanza un poco distinto, para verlos separados.
        final route = board.path(
          _positions[i],
          steps + i,
          (_) => (i + _moves) % 2,
        );
        _positions[i] = route.last;
      }
    });
  }

  void _reset() => setState(() {
    for (var i = 0; i < _positions.length; i++) {
      _positions[i] = 0;
    }
    _moves = 0;
  });

  GameState _state() {
    return GameState(
      players: {
        for (var i = 0; i < _count; i++)
          _idOf(i): PlayerState(
            id: _idOf(i),
            username: 'Jugador ${i + 1}',
            position: _positions[i],
          ),
      },
      turnOrder: [for (var i = 0; i < _count; i++) _idOf(i)],
      totalRounds: 10,
      diamondTileId: 1,
    );
  }

  @override
  Widget build(BuildContext context) {
    final map = ref.watch(boardMapProvider);
    final texture = ref.watch(pathTextureProvider);
    final board = ref.watch(boardProvider);
    final mine = ref.watch(characterLookProvider);
    final looks = _looks(mine);

    Widget preview;
    if (map.hasError || texture.hasError) {
      preview = const Center(child: Text('No se pudo cargar el mapa.'));
    } else if (map.value == null || texture.value == null) {
      preview = const Center(child: CircularProgressIndicator());
    } else {
      preview = BoardMapView(
        // Se arma de nuevo si cambia la cantidad de jugadores.
        key: ValueKey(_count),
        map: map.value!,
        board: board,
        pathTexture: texture.value!,
        state: _state(),
        myId: _idOf(0),
        onChooseBranch: (_) {},
        looks: {for (var i = 0; i < _count; i++) _idOf(i): looks[i]},
      );
    }

    return AdminPage(
      title: 'Mapa con personajes',
      children: [
        SettingsSection(
          title: 'Jugadores',
          children: [
            Row(
              children: [
                const Text('Cantidad'),
                const SizedBox(width: 12),
                SegmentedButton<int>(
                  showSelectedIcon: false,
                  segments: [
                    for (var n = 1; n <= _maxPlayers; n++)
                      ButtonSegment(value: n, label: Text('$n')),
                  ],
                  selected: {_count},
                  onSelectionChanged: (value) =>
                      setState(() => _count = value.single),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'El primero lleva tu aspecto; los demás, aspectos de ejemplo. '
              'Avanza casillas para verlos caminar: de lado, y de espalda '
              'cuando suben por el mapa.',
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final steps in _steps)
                  FilledButton.tonal(
                    onPressed: () => _advance(steps),
                    child: Text(
                      steps == 1 ? 'Avanzar 1 casilla' : 'Avanzar $steps',
                    ),
                  ),
                OutlinedButton(
                  onPressed: _reset,
                  child: const Text('Volver a la salida'),
                ),
              ],
            ),
          ],
        ),
        SettingsSection(
          title: 'Mapa',
          children: [SizedBox(height: 460, child: ClipRect(child: preview))],
        ),
      ],
    );
  }
}
