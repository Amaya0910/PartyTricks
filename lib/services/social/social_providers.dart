import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:party_tricks/models/social/chat_message.dart';
import 'package:party_tricks/models/social/chat_summary.dart';
import 'package:party_tricks/models/social/friendship.dart';
import 'package:party_tricks/models/social/party_invite.dart';
import 'package:party_tricks/models/social/public_profile.dart';
import 'package:party_tricks/services/auth/auth_providers.dart';
import 'package:party_tricks/services/social/chat_service.dart';
import 'package:party_tricks/services/social/firebase_chat_service.dart';
import 'package:party_tricks/services/social/firebase_friends_service.dart';
import 'package:party_tricks/services/social/firebase_invite_service.dart';
import 'package:party_tricks/services/social/firebase_moderation_service.dart';
import 'package:party_tricks/services/social/firebase_profile_directory.dart';
import 'package:party_tricks/services/social/firestore_social_paths.dart';
import 'package:party_tricks/services/social/friends_sections.dart';
import 'package:party_tricks/services/social/friends_service.dart';
import 'package:party_tricks/services/social/invite_service.dart';
import 'package:party_tricks/services/social/moderation_service.dart';
import 'package:party_tricks/services/social/profile_directory.dart';

// ---------------------------------------------------------------------------
// Servicios (en las pruebas se cambian por versiones falsas)
// ---------------------------------------------------------------------------

final socialPathsProvider = Provider<FirestoreSocialPaths>(
  (ref) => FirestoreSocialPaths(FirebaseFirestore.instance),
);

final profileDirectoryProvider = Provider<ProfileDirectory>(
  (ref) => FirebaseProfileDirectory(ref.watch(socialPathsProvider)),
);

final friendsServiceProvider = Provider<FriendsService>(
  (ref) => FirebaseFriendsService(ref.watch(socialPathsProvider)),
);

final moderationServiceProvider = Provider<ModerationService>(
  (ref) => FirebaseModerationService(ref.watch(socialPathsProvider)),
);

final chatServiceProvider = Provider<ChatService>(
  (ref) => FirebaseChatService(ref.watch(socialPathsProvider)),
);

final inviteServiceProvider = Provider<InviteService>(
  (ref) => FirebaseInviteService(ref.watch(socialPathsProvider)),
);

// ---------------------------------------------------------------------------
// Datos en vivo del jugador con la sesión iniciada
// ---------------------------------------------------------------------------

/// Uid del jugador con la sesión iniciada, o null.
final currentUidProvider = Provider<String?>(
  (ref) => ref.watch(userProfileProvider.select((p) => p.value?.uid)),
);

/// Solicitudes y amistades del jugador.
final friendshipsProvider = StreamProvider<List<Friendship>>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return Stream.value(const []);
  return ref.watch(friendsServiceProvider).watchFriendships(uid);
});

/// Chats del jugador por id (el id es el mismo de la amistad).
final chatsProvider = StreamProvider<Map<String, ChatSummary>>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return Stream.value(const {});
  return ref
      .watch(chatServiceProvider)
      .watchChats(uid)
      .map((chats) => {for (final chat in chats) chat.id: chat});
});

/// Las amistades separadas como se muestran en la pantalla.
final friendsSectionsProvider = Provider<FriendsSections>((ref) {
  final uid = ref.watch(currentUidProvider);
  final all = ref.watch(friendshipsProvider).value;
  if (uid == null || all == null) return const FriendsSections();
  return FriendsSections.build(
    myUid: uid,
    all: all,
    chats: ref.watch(chatsProvider).value ?? const {},
  );
});

/// Uids de los amigos aceptados.
final friendUidsProvider = Provider<Set<String>>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return const {};
  return {
    for (final f in ref.watch(friendsSectionsProvider).friends) f.otherOf(uid),
  };
});

/// Uids que el jugador tiene bloqueados.
final blockedUidsProvider = StreamProvider<Set<String>>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return Stream.value(const {});
  return ref.watch(moderationServiceProvider).watchBlocked(uid);
});

/// Invitaciones que el jugador aún no ha visto.
final pendingInvitesProvider = StreamProvider<List<PartyInvite>>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return Stream.value(const []);
  return ref.watch(inviteServiceProvider).watchPending(uid);
});

/// Perfil público de cualquier jugador, por uid.
final publicProfileProvider = StreamProvider.autoDispose
    .family<PublicProfile?, String>(
      (ref, uid) => ref.watch(profileDirectoryProvider).watchProfile(uid),
    );

/// Mensajes de un chat, por id.
final chatMessagesProvider = StreamProvider.autoDispose
    .family<List<ChatMessage>, String>(
      (ref, chatId) => ref.watch(chatServiceProvider).watchMessages(chatId),
    );
