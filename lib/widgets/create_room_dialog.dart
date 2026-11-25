import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:party_tricks/models/room.dart';
import 'package:party_tricks/screens/map_selector_screen.dart';
import 'package:party_tricks/services/map/map_catalog.dart';
import 'package:party_tricks/services/map/map_providers.dart';
import 'package:party_tricks/services/map/remote_map_config.dart';
import 'package:party_tricks/theme/app_colors.dart';
import 'package:party_tricks/widgets/animated_mode_switch.dart';
import 'package:party_tricks/widgets/blurred_dialog.dart';
import 'package:party_tricks/widgets/fx/party_button.dart';
import 'package:party_tricks/widgets/fx/pop_in.dart';
import 'package:party_tricks/widgets/fx/pressable_scale.dart';
import 'package:party_tricks/widgets/map/map_preview_image.dart';
import 'package:party_tricks/widgets/party_pill.dart';
import 'package:party_tricks/widgets/step_dot_slider.dart';

/// "Alista tu party": opciones para crear una sala.
/// Devuelve la configuración o null si se cierra.
class CreateRoomDialog extends StatefulWidget {
  const CreateRoomDialog({
    super.key,
    required this.remote,
    this.maps = MapCatalog.all,
    this.random,
  });

  /// Con qué se sortea el mapa si se pide "Mapa aleatorio" (en las pruebas
  /// se da uno fijo).
  final Random? random;

  /// Los mapas para elegir. Solo se muestran los listos
  /// (`MapDefinition.selectable`) y encendidos en [remote]. Empieza en
  /// [MapCatalog.defaultMap].
  final List<MapDefinition> maps;

  /// Qué mapas están encendidos desde Firebase. Si cambia con el diálogo
  /// abierto, la lista se actualiza; si se apaga el mapa elegido, vuelve al
  /// de por defecto.
  final RemoteMapConfig remote;

  static Future<RoomSettings?> show(BuildContext context) {
    return showBlurredDialog<RoomSettings>(
      context,
      builder: (_) => Consumer(
        builder: (context, ref, _) => CreateRoomDialog(
          remote:
              ref.watch(remoteMapConfigProvider).value ??
              RemoteMapConfig.unavailable,
        ),
      ),
    );
  }

  @override
  State<CreateRoomDialog> createState() => _CreateRoomDialogState();
}

class _CreateRoomDialogState extends State<CreateRoomDialog> {
  static const int _defaultPlayers = 3;
  static const int _defaultRounds = 10;

  /// Los deslizadores dibujan un punto por cada valor desde 1.
  static const int _firstDot = 1;

  bool _isPrivate = true;
  int _maxPlayers = _defaultPlayers;
  int _rounds = _defaultRounds;
  String _mapId = MapCatalog.defaultMap.id;

  /// Si el mapa se sortea entre los disponibles al crear la sala.
  bool _randomMap = false;

  List<MapDefinition> get _maps => widget.remote.availableOf(widget.maps);

  /// El elegido, si sigue disponible; si no, el de por defecto (o el
  /// primero que haya).
  MapDefinition get _map {
    final maps = _maps;
    MapDefinition? find(String id) {
      for (final map in maps) {
        if (map.id == id) return map;
      }
      return null;
    }

    return find(_mapId) ?? find(MapCatalog.defaultMap.id) ?? maps.first;
  }

  /// El mapa de la sala: el elegido o, con "Mapa aleatorio", uno sorteado
  /// entre los disponibles (la sala siempre guarda un mapa concreto).
  MapDefinition _mapToPlay() {
    final maps = _maps;
    if (!_randomMap || maps.length < 2) return _map;
    return maps[(widget.random ?? Random()).nextInt(maps.length)];
  }

  RoomSettings _buildSettings() {
    return RoomSettings(
      isPublic: !_isPrivate,
      maxPlayers: _maxPlayers,
      rounds: _rounds,
      mapId: _mapToPlay().id,
    );
  }

  Future<void> _chooseMap() async {
    final id = await MapSelectorScreen.show(
      context,
      selectedId: _map.id,
      rounds: _rounds,
      players: _maxPlayers,
      remote: widget.remote,
      maps: _maps,
    );
    if (id == null || !mounted) return;
    setState(() {
      _mapId = id;
      _randomMap = false;
    });
  }

  void _submit() => Navigator.of(context).pop(_buildSettings());

  @override
  Widget build(BuildContext context) {
    return DialogCard(
      title: 'Alista tu party',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          // Cada bloque entra un poquito después del anterior.
          children: [
            for (final (index, section) in _sections().indexed)
              PopIn.staggered(
                index: index,
                base: const Duration(milliseconds: 100),
                from: const Offset(0, 0.3),
                child: section,
              ),
          ],
        ),
      ),
    );
  }

  /// Las partes del diálogo, en orden.
  List<Widget> _sections() => [
    _MapRow(map: _map, random: _randomMap, onTap: _chooseMap),
    if (_maps.length > 1)
      Padding(
        padding: const EdgeInsets.only(top: 8),
        child: _RandomMapRow(
          value: _randomMap,
          onChanged: (value) => setState(() => _randomMap = value),
        ),
      ),
    Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SettingLabel('Jugadores: $_maxPlayers'),
          const SizedBox(height: 8),
          StepDotSlider(
            start: _firstDot,
            min: Room.minPlayers,
            max: Room.maxAllowedPlayers,
            value: _maxPlayers,
            onChanged: (value) => setState(() => _maxPlayers = value),
          ),
        ],
      ),
    ),
    Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SettingLabel('Rondas: $_rounds'),
          const SizedBox(height: 8),
          StepDotSlider(
            start: _firstDot,
            min: Room.minRounds,
            max: Room.maxRounds,
            value: _rounds,
            dotSize: 7,
            showLine: false,
            onChanged: (value) => setState(() => _rounds = value),
          ),
        ],
      ),
    ),
    Padding(
      padding: const EdgeInsets.only(top: 20),
      child: _VisibilityRow(
        isPrivate: _isPrivate,
        onChanged: (value) => setState(() => _isPrivate = value),
      ),
    ),
    Padding(
      padding: const EdgeInsets.only(top: 24),
      child: PartyButton(
        label: 'Crear',
        icon: Icons.celebration_rounded,
        onPressed: _submit,
      ),
    ),
  ];
}

/// El mapa elegido; al tocarlo se abre el selector.
class _MapRow extends StatelessWidget {
  const _MapRow({required this.map, required this.onTap, this.random = false});

  final MapDefinition map;
  final VoidCallback onTap;

  /// Con "Mapa aleatorio" se muestra un dado en vez del mapa.
  final bool random;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      key: const Key('choose-map'),
      onTap: onTap,
      pressedScale: 0.96,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.authField,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.authAccent, width: 2),
          boxShadow: const [
            BoxShadow(
              color: AppColors.authShadow,
              blurRadius: 0,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 52,
                  height: 52,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, animation) => RotationTransition(
                      turns: Tween<double>(begin: -0.25, end: 0).animate(
                        CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOutBack,
                        ),
                      ),
                      child: FadeTransition(opacity: animation, child: child),
                    ),
                    child: random
                        ? const ColoredBox(
                            key: ValueKey('random'),
                            color: AppColors.authAccent,
                            child: Icon(
                              Icons.casino_rounded,
                              color: AppColors.white,
                              size: 30,
                            ),
                          )
                        : MapPreviewImage(
                            key: ValueKey(map.id),
                            map: map,
                            decodeWidth: 120,
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Mapa',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.authHint,
                      ),
                    ),
                    Text(
                      random ? 'Aleatorio' : map.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppColors.authAccent,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.authAccent),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Mapa aleatorio": al crear la sala se sortea uno de los disponibles.
class _RandomMapRow extends StatelessWidget {
  const _RandomMapRow({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.casino_rounded, color: AppColors.authAccent),
        const SizedBox(width: 8),
        const Expanded(
          child: Text(
            'Mapa aleatorio',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.authAccent,
            ),
          ),
        ),
        Switch(
          key: const Key('random-map'),
          value: value,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

/// Etiqueta azul en forma de píldora ("Jugadores: 3", "Rondas: 10").
class _SettingLabel extends StatelessWidget {
  const _SettingLabel(this.text);

  final String text;

  static const double _widthFactor = 0.68;

  @override
  Widget build(BuildContext context) =>
      PartyPill(label: text, widthFactor: _widthFactor, fontSize: 18);
}

/// "Lista de invitados" con su subtítulo y el interruptor privado/público.
class _VisibilityRow extends StatelessWidget {
  const _VisibilityRow({required this.isPrivate, required this.onChanged});

  final bool isPrivate;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Lista de invitados',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.authAccent,
                ),
              ),
              Text(
                isPrivate ? 'Solo con código' : 'Fiesta para todos (pública)',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.authHint,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        AnimatedModeSwitch(isPrivate: isPrivate, onChanged: onChanged),
      ],
    );
  }
}
