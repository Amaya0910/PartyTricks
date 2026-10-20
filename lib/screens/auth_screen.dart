import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:party_tricks/services/auth/auth_providers.dart';
import 'package:party_tricks/theme/app_colors.dart';
import 'package:party_tricks/widgets/flip_card.dart';
import 'package:party_tricks/widgets/login_card.dart';
import 'package:party_tricks/widgets/register_card.dart';

/// Pantalla de acceso: una tarjeta que da la vuelta entre el inicio de sesión
/// y el registro, sobre el fondo del juego con solo las nubes a la vista.
class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  /// Qué parte del alto del dibujo de fondo se baja fuera de la pantalla para
  /// que solo se vean las nubes de abajo. 0 muestra el dibujo entero y 0.9
  /// casi todo escondido. Ajústalo hasta que se vea como quieres.
  static const double _hiddenFraction = 0.6;

  static const double _cardHeight = 470;
  static const double _cardMaxWidth = 360;

  bool _showRegister = false;

  void _flipTo({required bool register}) {
    // El error de una cara no tiene sentido en la otra.
    ref.read(authControllerProvider.notifier).clearError();
    FocusScope.of(context).unfocus();
    setState(() => _showRegister = register);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.screenBackground,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Align(
            alignment: Alignment.bottomCenter,
            child: FractionalTranslation(
              translation: const Offset(0, _hiddenFraction),
              child: Image.asset(
                'assets/images/Fondo_Principal.png',
                width: double.infinity,
                fit: BoxFit.fitWidth,
                alignment: Alignment.bottomCenter,
                // Si falta la imagen, se ve el color liso del cielo.
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: _cardMaxWidth,
                          ),
                          child: SizedBox(
                            height: _cardHeight,
                            child: FlipCard(
                              showBack: _showRegister,
                              front: LoginCard(
                                onShowRegister: () => _flipTo(register: true),
                              ),
                              back: RegisterCard(
                                onShowLogin: () => _flipTo(register: false),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}