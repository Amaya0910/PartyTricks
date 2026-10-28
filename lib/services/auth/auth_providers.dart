import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:party_tricks/controllers/auth_controller.dart';
import 'package:party_tricks/models/auth_form_state.dart';
import 'package:party_tricks/models/auth_user.dart';
import 'package:party_tricks/models/user_profile.dart';
import 'package:party_tricks/services/auth/account_service.dart';
import 'package:party_tricks/services/auth/auth_service.dart';
import 'package:party_tricks/services/auth/firebase_account_service.dart';
import 'package:party_tricks/services/auth/firebase_auth_service.dart';
import 'package:party_tricks/services/auth/friend_code_generator.dart';
import 'package:party_tricks/services/auth/google_id_token_source.dart';

final authServiceProvider = Provider<AuthService>(
  (ref) => FirebaseAuthService(
    auth: FirebaseAuth.instance,
    firestore: FirebaseFirestore.instance,
    codeGenerator: FriendCodeGenerator(),
    google: GoogleSignInTokenSource(),
  ),
);

/// Cambios de cuenta desde Ajustes.
final accountServiceProvider = Provider<AccountService>(
  (ref) => FirebaseAccountService(
    auth: FirebaseAuth.instance,
    firestore: FirebaseFirestore.instance,
    codeGenerator: FriendCodeGenerator(),
  ),
);

/// La sesión en vivo: correo verificado y formas de entrar. Es null si no
/// hay sesión.
final authUserProvider = StreamProvider<AuthUser?>(
  (ref) => ref.watch(authServiceProvider).watchAuthUser(),
);

/// El perfil del jugador en vivo. Es null si no hay sesión.
final userProfileProvider = StreamProvider<UserProfile?>(
  (ref) => ref.watch(authServiceProvider).watchProfile(),
);

/// Lógica de las pantallas de registro e inicio de sesión.
final authControllerProvider = NotifierProvider<AuthController, AuthFormState>(
  AuthController.new,
);
