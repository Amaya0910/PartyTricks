import 'package:flutter/material.dart';
import 'package:party_tricks/models/character_look.dart';
import 'package:party_tricks/models/character_view.dart';
import 'package:party_tricks/widgets/character/animated_character.dart';
import 'package:party_tricks/widgets/character/walking_character.dart';

/// Las animaciones del personaje, en un solo lugar. La vista previa de
/// administración recorre esta lista: **al crear una animación nueva, se
/// agrega aquí y aparece sola**.
enum CharacterClip {
  idle(
    'Reposo',
    'De frente: respira, la cabeza y los brazos suben un poco.',
    CharacterView.frente,
    Duration(milliseconds: 2500),
  ),
  idleSide(
    'Reposo de lado',
    'De lado: parado, respira y mueve un poco los brazos. Solo se ve en el '
        'Vestuario.',
    CharacterView.lado,
    Duration(milliseconds: 2500),
  ),
  walk(
    'Caminar',
    'De lado: dos piernas y dos brazos, mirando hacia donde va. Es la del '
        'mapa.',
    CharacterView.lado,
    Duration(milliseconds: 700),
  );

  const CharacterClip(this.title, this.description, this.view, this.period);

  final String title;
  final String description;

  /// Desde dónde se ve (carpeta de arte que usa).
  final CharacterView view;

  /// Lo que dura una vuelta completa a velocidad normal.
  final Duration period;

  /// Si se puede voltear hacia la izquierda (las de lado).
  bool get canFlip => view == CharacterView.lado;

  /// El personaje en la fase [phase] (0 a 1) de esta animación.
  Widget build({
    Key? key,
    required CharacterLook look,
    required Animation<double> phase,
    bool faceRight = true,
  }) {
    switch (this) {
      case CharacterClip.idle:
        return AnimatedCharacter.fromLook(look, key: key, phase: phase);
      case CharacterClip.idleSide:
        return WalkingCharacter(
          key: key,
          phase: phase,
          look: look,
          faceRight: faceRight,
          cycle: const SideIdle(),
        );
      case CharacterClip.walk:
        return WalkingCharacter(
          key: key,
          phase: phase,
          look: look,
          faceRight: faceRight,
        );
    }
  }
}
