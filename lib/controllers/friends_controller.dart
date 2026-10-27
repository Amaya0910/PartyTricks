import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:party_tricks/controllers/social_guard.dart';
import 'package:party_tricks/models/social/friendship.dart';
import 'package:party_tricks/services/auth/auth_providers.dart';
import 'package:party_tricks/services/social/chat_rules.dart';
import 'package:party_tricks/services/social/friends_service.dart';
import 'package:party_tricks/services/social/social_exception.dart';
import 'package:party_tricks/services/social/social_providers.dart';
import 'package:party_tricks/services/stats/stats_providers.dart';

/// Solicitudes de amistad: enviar por código, aceptar, rechazar, cancelar y
/// eliminar. Lanza [SocialException] con el mensaje para mostrar.
class FriendsController {
  FriendsController(this._ref);

  final Ref _ref;

  String get _uid {
    final uid = _ref.read(currentUidProvider);
    if (uid == null) throw const SocialException('Inicia sesión primero.');
    return uid;
  }

  /// Envía una solicitud al dueño de [code]. Devuelve el mensaje de éxito.
  Future<String> addByCode(String code) {
    return guardSocial(() async {
      final error = ChatRules.friendCodeError(code);
      if (error != null) throw SocialException(error);
      final clean = ChatRules.normalizeFriendCode(code);

      final me = _uid;
      final myCode = _ref.read(userProfileProvider).value?.friendCode;
      if (clean == myCode) {
        throw const SocialException('Ese es tu propio código.');
      }

      final other = await _ref
          .read(profileDirectoryProvider)
          .findUidByFriendCode(clean);
      if (other == null) {
        throw const SocialException('No existe un jugador con ese código.');
      }

      final moderation = _ref.read(moderationServiceProvider);
      if (await moderation.isBlocked(blockerUid: me, uid: other)) {
        throw const SocialException(
          'Bloqueaste a este jugador. Desbloquéalo en Ajustes para agregarlo.',
        );
      }
      // No se le dice que lo bloquearon: solo que no se pudo.
      if (await moderation.isBlocked(blockerUid: other, uid: me)) {
        throw const SocialException('No se pudo enviar la solicitud.');
      }

      final result = await _ref
          .read(friendsServiceProvider)
          .sendRequest(fromUid: me, toUid: other, at: _now());
      return switch (result) {
        FriendRequestResult.sent => 'Solicitud enviada.',
        FriendRequestResult.accepted => '¡Ahora son amigos!',
      };
    });
  }

  Future<void> accept(Friendship request) {
    return guardSocial(
      () => _ref.read(friendsServiceProvider).accept(request.id),
    );
  }

  /// Rechazar, cancelar y eliminar borran la amistad.
  Future<void> remove(Friendship friendship) {
    return guardSocial(
      () => _ref.read(friendsServiceProvider).remove(friendship.id),
    );
  }

  DateTime _now() => _ref.read(clockProvider)();
}

final friendsControllerProvider = Provider<FriendsController>(
  FriendsController.new,
);

/// Con qué amigo está abierto el chat (su uid), o null si se ve la lista.
/// El chat se abre dentro de la pestaña Amigos, como en el mockup.
class OpenChatController extends Notifier<String?> {
  @override
  String? build() => null;

  void open(String friendUid) => state = friendUid;

  void close() => state = null;
}

final openChatProvider = NotifierProvider<OpenChatController, String?>(
  OpenChatController.new,
);
