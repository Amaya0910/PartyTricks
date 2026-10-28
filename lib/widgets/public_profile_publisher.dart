import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:party_tricks/controllers/public_profile_controller.dart';
import 'package:party_tricks/models/user_profile.dart';
import 'package:party_tricks/services/auth/auth_providers.dart';

/// Mantiene el perfil público (`publicProfiles/{uid}`) al día cada vez que
/// cambia el perfil del jugador. No dibuja nada: solo envuelve a [child].
class PublicProfilePublisher extends ConsumerStatefulWidget {
  const PublicProfilePublisher({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<PublicProfilePublisher> createState() =>
      _PublicProfilePublisherState();
}

class _PublicProfilePublisherState
    extends ConsumerState<PublicProfilePublisher> {
  @override
  void initState() {
    super.initState();
    // fireImmediately: también publica el perfil que ya está cargado.
    ref.listenManual<AsyncValue<UserProfile?>>(userProfileProvider, (
      _,
      next,
    ) {
      final profile = next.value;
      if (profile != null) {
        ref.read(publicProfileControllerProvider).sync(profile);
      }
    }, fireImmediately: true);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
