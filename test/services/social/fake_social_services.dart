import 'dart:async';

import 'package:party_tricks/models/social/chat_message.dart';
import 'package:party_tricks/models/social/chat_summary.dart';
import 'package:party_tricks/models/social/friendship.dart';
import 'package:party_tricks/models/social/party_invite.dart';
import 'package:party_tricks/models/social/public_profile.dart';
import 'package:party_tricks/models/social/report_reason.dart';
import 'package:party_tricks/services/social/chat_service.dart';
import 'package:party_tricks/services/social/friends_service.dart';
import 'package:party_tricks/services/social/invite_service.dart';
import 'package:party_tricks/services/social/moderation_service.dart';
import 'package:party_tricks/services/social/pair_id.dart';
import 'package:party_tricks/services/social/profile_directory.dart';

/// Perfiles públicos en memoria.
class FakeProfileDirectory implements ProfileDirectory {
  /// Código de amistad → uid.
  final codes = <String, String>{};
  final published = <PublicProfile>[];

  @override
  Stream<PublicProfile?> watchProfile(String uid) => Stream.value(null);

  @override
  Future<String?> findUidByFriendCode(String code) async => codes[code];

  @override
  Future<void> publish(PublicProfile profile) async => published.add(profile);
}

/// Amistades en memoria.
class FakeFriendsService implements FriendsService {
  /// Lo que devuelve la próxima solicitud.
  FriendRequestResult nextResult = FriendRequestResult.sent;
  final requests = <(String, String)>[];
  final accepted = <String>[];
  final removed = <String>[];

  @override
  Stream<List<Friendship>> watchFriendships(String uid) =>
      Stream.value(const []);

  @override
  Future<FriendRequestResult> sendRequest({
    required String fromUid,
    required String toUid,
    required DateTime at,
  }) async {
    requests.add((fromUid, toUid));
    return nextResult;
  }

  @override
  Future<void> accept(String friendshipId) async => accepted.add(friendshipId);

  @override
  Future<void> remove(String friendshipId) async => removed.add(friendshipId);
}

/// Bloqueos y reportes en memoria.
class FakeModerationService implements ModerationService {
  /// Pares (bloqueador, bloqueado).
  final blocks = <(String, String)>{};
  final reports = <(String, String, ReportReason)>[];

  @override
  Stream<Set<String>> watchBlocked(String uid) => Stream.value({
    for (final (blocker, blocked) in blocks)
      if (blocker == uid) blocked,
  });

  @override
  Future<bool> isBlocked({
    required String blockerUid,
    required String uid,
  }) async => blocks.contains((blockerUid, uid));

  @override
  Future<void> block({
    required String uid,
    required String otherUid,
    required DateTime at,
  }) async => blocks.add((uid, otherUid));

  @override
  Future<void> unblock({required String uid, required String otherUid}) async {
    blocks.remove((uid, otherUid));
  }

  @override
  Future<void> report({
    required String reporterUid,
    required String reportedUid,
    required ReportReason reason,
    required DateTime at,
  }) async => reports.add((reporterUid, reportedUid, reason));
}

/// Chat en memoria.
class FakeChatService implements ChatService {
  /// Si no es null, el próximo envío lanza este error.
  Object? nextError;
  final sent = <(String, String, ChatMessage)>[];
  final reads = <(String, String)>[];

  @override
  Stream<List<ChatSummary>> watchChats(String uid) => Stream.value(const []);

  @override
  Stream<List<ChatMessage>> watchMessages(String chatId) =>
      Stream.value(const []);

  @override
  Future<void> send({
    required String fromUid,
    required String toUid,
    required ChatMessage message,
  }) async {
    final error = nextError;
    if (error != null) {
      nextError = null;
      throw error;
    }
    sent.add((fromUid, toUid, message));
  }

  @override
  Future<void> markRead({
    required String chatId,
    required String uid,
    required DateTime at,
  }) async => reads.add((chatId, uid));
}

/// Invitaciones en memoria.
class FakeInviteService implements InviteService {
  final sent = <PartyInvite>[];
  final seen = <String>[];
  final _pending = StreamController<List<PartyInvite>>.broadcast();

  void emit(List<PartyInvite> invites) => _pending.add(invites);

  @override
  Stream<List<PartyInvite>> watchPending(String uid) => _pending.stream;

  @override
  Future<void> send(PartyInvite invite) async => sent.add(invite);

  @override
  Future<void> markSeen(String inviteId) async => seen.add(inviteId);
}

/// Amistad aceptada entre [a] y [b], para las pruebas.
Friendship friendshipOf(
  String a,
  String b, {
  FriendshipStatus status = FriendshipStatus.accepted,
  String? requestedBy,
  DateTime? createdAt,
}) {
  return Friendship(
    id: PairId.of(a, b),
    members: PairId.members(a, b),
    requestedBy: requestedBy ?? a,
    status: status,
    createdAt: createdAt,
  );
}
