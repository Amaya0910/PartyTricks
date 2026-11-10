import 'dart:math';

import 'package:flutter/material.dart';
import 'package:party_tricks/models/skin_tone.dart';
import 'package:party_tricks/screens/admin/admin_page.dart';
import 'package:party_tricks/screens/admin/admin_samples.dart';
import 'package:party_tricks/screens/admin/animation_preview_screen.dart';
import 'package:party_tricks/screens/admin/minigame_practice_screen.dart';
import 'package:party_tricks/screens/results_screen.dart';
import 'package:party_tricks/theme/app_colors.dart';
import 'package:party_tricks/widgets/character/animated_character.dart';
import 'package:party_tricks/widgets/confirm_dialog.dart';
import 'package:party_tricks/widgets/create_room_dialog.dart';
import 'package:party_tricks/widgets/dice_roll_overlay.dart';
import 'package:party_tricks/widgets/minigames/minigame_result_overlay.dart';
import 'package:party_tricks/widgets/party_character.dart';
import 'package:party_tricks/widgets/settings_section.dart';
import 'package:party_tricks/widgets/skin_tone_picker.dart';

/// Galería de pantallas: abre cada pantalla del juego con datos de ejemplo,
/// sin jugar una partida. Nada de lo que se toca aquí se guarda.
class AdminGalleryScreen extends StatelessWidget {
  const AdminGalleryScreen({super.key});

  static Route<void> route() =>
      MaterialPageRoute(builder: (_) => const AdminGalleryScreen());

  @override
  Widget build(BuildContext context) {
    void open(Widget screen) => Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => screen));

    return AdminPage(
      title: 'Galería de pantallas',
      children: [
        SettingsSection(
          title: 'Partida',
          children: [
            SettingsTile(
              label: 'Practicar minijuegos',
              icon: Icons.sports_esports,
              onTap: () =>
                  Navigator.of(context).push(MinigamePracticeScreen.route()),
            ),
            SettingsTile(
              label: 'Resultados de minijuegos',
              icon: Icons.emoji_events,
              onTap: () => open(const _MinigameResultsPreview()),
            ),
            SettingsTile(
              label: 'Tirada del dado',
              icon: Icons.casino,
              onTap: () => open(const _DicePreview()),
            ),
            SettingsTile(
              label: 'Pantalla final',
              icon: Icons.flag,
              onTap: () => open(
                ResultsScreen(
                  game: AdminSamples.finishedGame,
                  myId: AdminSamples.me,
                  onExit: () => Navigator.of(context).pop(),
                ),
              ),
            ),
          ],
        ),
        SettingsSection(
          title: 'Personaje',
          children: [
            SettingsTile(
              label: 'Tonos de piel',
              icon: Icons.palette,
              onTap: () => open(const _CharacterPreview()),
            ),
            SettingsTile(
              label: 'Animaciones',
              icon: Icons.directions_walk,
              onTap: () =>
                  Navigator.of(context).push(AnimationPreviewScreen.route()),
            ),
          ],
        ),
        SettingsSection(
          title: 'Diálogos',
          children: [
            SettingsTile(
              label: 'Crear sala',
              icon: Icons.open_in_new,
              // Solo se abre: lo que se elija no crea ninguna sala.
              onTap: () => CreateRoomDialog.show(context),
            ),
            SettingsTile(
              label: 'Confirmación',
              icon: Icons.open_in_new,
              onTap: () => ConfirmDialog.show(
                context,
                title: 'Cerrar sesión',
                message: '¿Quieres cerrar sesión en este celular?',
                confirmLabel: 'Cerrar sesión',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Las tarjetas de resultado de cada minijuego, una debajo de otra.
class _MinigameResultsPreview extends StatelessWidget {
  const _MinigameResultsPreview();

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      title: 'Resultados de minijuegos',
      children: [
        for (final result in AdminSamples.results)
          MinigameResultCard(
            result: result,
            players: AdminSamples.minigamePlayers,
            coins: 10,
          ),
      ],
    );
  }
}

/// El dado sobre un fondo de tablero, con botones para lanzarlo.
class _DicePreview extends StatefulWidget {
  const _DicePreview();

  @override
  State<_DicePreview> createState() => _DicePreviewState();
}

class _DicePreviewState extends State<_DicePreview> {
  final _random = Random();
  DiceRoll? _roll;
  int _serial = 0;

  void _throw({int extra = 0, int boost = 0}) {
    setState(() {
      _roll = DiceRoll(
        serial: ++_serial,
        username: 'Tú',
        color: AppColors.players.first,
        value: _random.nextInt(6) + 1,
        extra: extra,
        boost: boost,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.screenBackground,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.settingsReload,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.chevron_left),
                      label: const Text('Volver'),
                    ),
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      FilledButton(
                        onPressed: _throw,
                        child: const Text('Lanzar'),
                      ),
                      FilledButton(
                        onPressed: () => _throw(extra: _random.nextInt(6) + 1),
                        child: const Text('Con dado extra'),
                      ),
                      FilledButton(
                        onPressed: () => _throw(boost: 3),
                        child: const Text('Con impulso'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            DiceRollOverlay(roll: _roll),
          ],
        ),
      ),
    );
  }
}

/// El personaje con cada tono de piel, sin guardar el que se elija.
class _CharacterPreview extends StatefulWidget {
  const _CharacterPreview();

  @override
  State<_CharacterPreview> createState() => _CharacterPreviewState();
}

class _CharacterPreviewState extends State<_CharacterPreview> {
  int _tone = SkinTone.defaultIndex;

  @override
  Widget build(BuildContext context) {
    final skin = SkinTone.colorOf(_tone);
    return AdminPage(
      title: 'Tonos de piel',
      children: [
        SettingsSection(
          title: 'Inicio y Vestuario',
          children: [
            SizedBox(height: 220, child: AnimatedCharacter(skinTone: skin)),
            Text('Tono ${_tone + 1} de ${SkinTone.count}'),
          ],
        ),
        SettingsSection(
          title: 'Sala y tablero',
          children: [
            // Todavía usa la piel fija (AppColors.characterSkin): aquí se
            // ve cuando el tono llegue a la sala y al tablero.
            SizedBox(
              height: 120,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (final color in AppColors.players)
                    Flexible(child: PartyCharacter(color: color, height: 90)),
                ],
              ),
            ),
          ],
        ),
        SizedBox(
          height: 300,
          child: SkinTonePicker(
            selected: _tone,
            onSelected: (index) => setState(() => _tone = index),
          ),
        ),
      ],
    );
  }
}
