import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:party_tricks/models/social/chat_summary.dart';
import 'package:party_tricks/services/game_engine/experience_calculator.dart';
import 'package:party_tricks/services/social/chat_format.dart';
import 'package:party_tricks/services/social/social_providers.dart';
import 'package:party_tricks/theme/app_colors.dart';
import 'package:party_tricks/widgets/level_pill.dart';
import 'package:party_tricks/widgets/profile_avatar.dart';

/// Un amigo en la lista: foto, nombre, nivel y el último mensaje, como en el
/// mockup. Un punto azul avisa si hay mensajes sin leer.
class FriendTile extends ConsumerWidget {
  const FriendTile({
    super.key,
    required this.friendUid,
    required this.myUid,
    required this.onTap,
    this.chat,
  });

  final String friendUid;
  final String myUid;
  final ChatSummary? chat;
  final VoidCallback onTap;

  static const _levels = ExperienceCalculator();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(publicProfileProvider(friendUid)).value;
    final unread = chat?.hasUnreadFor(myUid) ?? false;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.chatHeader,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.slotBorder, width: 2),
              ),
              child: ProfileAvatar(photoUrl: profile?.photoUrl, size: 52),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.friendsAccent, width: 2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            profile?.username ?? 'Jugador',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (profile != null)
                          LevelPill(
                            level: _levels.levelForXp(profile.experience),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            ChatFormat.preview(chat?.lastMessage, myUid),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: unread
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: AppColors.authText,
                            ),
                          ),
                        ),
                        if (unread)
                          Container(
                            key: const ValueKey('unread'),
                            width: 10,
                            height: 10,
                            margin: const EdgeInsets.only(left: 8),
                            decoration: const BoxDecoration(
                              color: AppColors.unreadDot,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
