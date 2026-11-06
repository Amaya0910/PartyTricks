import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:party_tricks/models/admin/app_overview.dart';
import 'package:party_tricks/services/admin/admin_service.dart';
import 'package:party_tricks/services/admin/firebase_admin_service.dart';
import 'package:party_tricks/services/auth/auth_providers.dart';

final adminServiceProvider = Provider<AdminService>(
  (ref) => FirebaseAdminService(FirebaseFirestore.instance),
);

/// Si la cuenta con la sesión iniciada es administradora, en vivo. Mientras
/// carga, sin sesión o si algo falla, es false.
final isAdminProvider = StreamProvider<bool>((ref) {
  final uid = ref.watch(userProfileProvider.select((p) => p.value?.uid));
  if (uid == null) return Stream.value(false);
  return ref.watch(adminServiceProvider).watchIsAdmin(uid);
});

/// Los números de toda la app. Se vuelven a pedir cada vez que se abre la
/// pantalla (o con `ref.invalidate`).
final appOverviewProvider = FutureProvider.autoDispose<AppOverview>(
  (ref) => ref.watch(adminServiceProvider).loadOverview(),
);
