import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:party_tricks/controllers/friends_controller.dart';
import 'package:party_tricks/controllers/invite_controller.dart';
import 'package:party_tricks/controllers/navigation_controller.dart';
import 'package:party_tricks/controllers/preferences_controller.dart';
import 'package:party_tricks/models/app_section.dart';
import 'package:party_tricks/models/notification_payload.dart';
import 'package:party_tricks/screens/invite_join.dart';
import 'package:party_tricks/services/auth/auth_providers.dart';
import 'package:party_tricks/services/notifications/notification_providers.dart';
import 'package:party_tricks/services/notifications/notification_service.dart';

/// Quién recibe notificaciones ahora: el uid del jugador con la sesión
/// iniciada, solo si tiene las notificaciones encendidas en Ajustes. Null si
/// no hay que avisarle a nadie.
final notificationTargetProvider = Provider<String?>((ref) {
  final uid = ref.watch(userProfileProvider.select((p) => p.value?.uid));
  final enabled = ref.watch(
    preferencesControllerProvider.select((p) => p.value?.notifications ?? true),
  );
  return enabled ? uid : null;
});

/// Mantiene las notificaciones funcionando mientras hay sesión: las activa
/// al iniciar sesión (o al encender el interruptor de Ajustes), las apaga al
/// salir, y atiende lo que el jugador hace con ellas. No dibuja nada más:
/// solo envuelve a [child].
///
/// - Tocar un mensaje abre ese chat en Amigos.
/// - Tocar una invitación lleva a Amigos (el aviso de invitación sale solo).
/// - **Aceptar** entra a la sala de la invitación y abre la sala de espera.
/// - **Rechazar** descarta la invitación.
class NotificationHost extends ConsumerStatefulWidget {
  const NotificationHost({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<NotificationHost> createState() => _NotificationHostState();
}

class _NotificationHostState extends ConsumerState<NotificationHost> {
  StreamSubscription<NotificationEvent>? _events;
  String? _active;

  /// Se guarda aquí porque en `dispose` ya no se puede leer con `ref`.
  late final NotificationService _service = ref.read(
    notificationServiceProvider,
  );

  @override
  void initState() {
    super.initState();
    _events = _service.events.listen(_handle);
    _switchTo(ref.read(notificationTargetProvider));
  }

  @override
  void dispose() {
    _events?.cancel();
    final active = _active;
    if (active != null) {
      unawaited(_service.stop(active));
    }
    super.dispose();
  }

  /// Con la app abierta: un mensaje se avisa salvo que ya tengas ese chat
  /// abierto. Las invitaciones no, porque ya salen en un aviso dentro de la
  /// app.
  bool _shouldShow(NotificationPayload payload) {
    if (payload.isInvite) return false;
    return ref.read(openChatProvider) != payload.fromUid;
  }

  Future<void> _switchTo(String? uid) async {
    if (uid == _active) return;
    final service = _service;
    final previous = _active;
    _active = uid;
    try {
      if (previous != null) await service.stop(previous);
      if (uid != null) await service.start(uid, shouldShow: _shouldShow);
    } catch (_) {
      // Sin permiso o sin conexión: la app sigue funcionando sin avisos.
    }
  }

  Future<void> _handle(NotificationEvent event) async {
    if (!mounted) return;
    final payload = event.payload;
    final invites = ref.read(inviteControllerProvider);
    switch (event.reply) {
      case NotificationReply.open:
        ref
            .read(navigationControllerProvider.notifier)
            .select(AppSection.friends);
        if (!payload.isInvite) {
          ref.read(openChatProvider.notifier).open(payload.fromUid);
        }
      case NotificationReply.accept:
        final code = payload.roomCode;
        final inviteId = payload.inviteId;
        if (code == null) return;
        // Ya la atendió: que no vuelva a salir el aviso dentro de la app.
        if (inviteId != null) await invites.markSeen(inviteId);
        if (!mounted) return;
        await joinPartyFromInvite(context, ref, code);
      case NotificationReply.decline:
        final inviteId = payload.inviteId;
        if (inviteId != null) await invites.decline(inviteId);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(notificationTargetProvider, (_, next) => _switchTo(next));
    return widget.child;
  }
}
