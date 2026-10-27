import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:party_tricks/controllers/social_guard.dart';
import 'package:party_tricks/controllers/stats_controller.dart';
import 'package:party_tricks/models/social/chat_message.dart';
import 'package:party_tricks/models/stats/social_stats.dart';
import 'package:party_tricks/services/social/chat_rules.dart';
import 'package:party_tricks/services/social/pair_id.dart';
import 'package:party_tricks/services/social/social_exception.dart';
import 'package:party_tricks/services/social/social_providers.dart';
import 'package:party_tricks/services/stats/stats_providers.dart';

/// Enviar mensajes y marcar el chat como leído. Lanza [SocialException] con
/// el mensaje para mostrar.
class ChatController {
  ChatController(this._ref);

  final Ref _ref;

  String get _uid {
    final uid = _ref.read(currentUidProvider);
    if (uid == null) throw const SocialException('Inicia sesión primero.');
    return uid;
  }

  /// Envía [text] a [friendUid]. Solo se puede escribir a amigos que no
  /// te hayan bloqueado.
  Future<void> send({required String friendUid, required String text}) {
    return guardSocial(() async {
      final error = ChatRules.messageError(text);
      if (error != null) throw SocialException(error);

      final me = _uid;
      if (!_ref.read(friendUidsProvider).contains(friendUid)) {
        throw const SocialException('Solo puedes escribirles a tus amigos.');
      }
      final blocked = await _ref
          .read(moderationServiceProvider)
          .isBlocked(blockerUid: friendUid, uid: me);
      if (blocked) {
        throw const SocialException('No puedes enviarle mensajes.');
      }

      await _ref
          .read(chatServiceProvider)
          .send(
            fromUid: me,
            toUid: friendUid,
            message: ChatMessage(
              id: '',
              senderId: me,
              text: ChatRules.cleanMessage(text)!,
              sentAt: _ref.read(clockProvider)(),
            ),
          );
      await _ref
          .read(statsControllerProvider)
          .recordSocial(SocialCounter.messageSent);
    });
  }

  /// Marca como leído el chat con [friendUid]. Si falla, no importa: solo
  /// quedaría el punto de "sin leer".
  Future<void> markRead(String friendUid) async {
    final me = _ref.read(currentUidProvider);
    if (me == null) return;
    try {
      await _ref
          .read(chatServiceProvider)
          .markRead(
            chatId: PairId.of(me, friendUid),
            uid: me,
            at: _ref.read(clockProvider)(),
          );
    } catch (_) {
      // Se reintenta la próxima vez que abra el chat.
    }
  }
}

final chatControllerProvider = Provider<ChatController>(ChatController.new);
