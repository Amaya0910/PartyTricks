import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:party_tricks/controllers/invite_controller.dart';
import 'package:party_tricks/screens/lobby_screen.dart';
import 'package:party_tricks/services/social/social_exception.dart';

/// Entra a la party de una invitación y abre la sala de espera. Si no se
/// puede (ya empezó, está llena...), muestra el motivo.
///
/// La usan el chat (botón "Unirse") y el aviso emergente.
Future<void> joinPartyFromInvite(
  BuildContext context,
  WidgetRef ref,
  String roomCode,
) async {
  final navigator = Navigator.of(context);
  final messenger = ScaffoldMessenger.of(context);
  try {
    final room = await ref.read(inviteControllerProvider).accept(roomCode);
    await navigator.push(LobbyScreen.route(room.id));
  } on SocialException catch (error) {
    messenger.showSnackBar(SnackBar(content: Text(error.message)));
  }
}
