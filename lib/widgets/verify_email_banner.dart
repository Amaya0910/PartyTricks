import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:party_tricks/controllers/account_controller.dart';
import 'package:party_tricks/services/auth/auth_providers.dart';
import 'package:party_tricks/services/auth/auth_service.dart';
import 'package:party_tricks/theme/app_colors.dart';

/// Aviso para verificar el correo. Se puede jugar sin verificar; el aviso
/// sale en Inicio y en Ajustes hasta que el jugador abra el enlace. Las
/// cuentas de Google no lo ven (Google ya verifica el correo).
class VerifyEmailBanner extends ConsumerStatefulWidget {
  const VerifyEmailBanner({super.key});

  @override
  ConsumerState<VerifyEmailBanner> createState() => _VerifyEmailBannerState();
}

class _VerifyEmailBannerState extends ConsumerState<VerifyEmailBanner> {
  bool _busy = false;

  Future<void> _run(Future<String> Function() action) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      final message = await action();
      messenger.showSnackBar(SnackBar(content: Text(message)));
    } on AuthException catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authUserProvider).value;
    if (user == null || !user.needsEmailVerification) {
      return const SizedBox.shrink();
    }
    final account = ref.read(accountControllerProvider);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 6),
      decoration: BoxDecoration(
        color: AppColors.pillBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.coin, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.mark_email_unread, color: AppColors.coin),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Verifica tu correo: te enviamos un enlace a ${user.email}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.authText,
                  ),
                ),
              ),
            ],
          ),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 4,
            children: [
              TextButton(
                onPressed: _busy
                    ? null
                    : () => _run(() async {
                        await account.sendEmailVerification();
                        return 'Te enviamos otro enlace. Revisa también '
                            'el correo no deseado.';
                      }),
                child: const Text('Reenviar'),
              ),
              TextButton(
                onPressed: _busy
                    ? null
                    : () => _run(() async {
                        final verified = await account.checkEmailVerified();
                        return verified
                            ? '¡Correo verificado!'
                            : 'Todavía no aparece verificado. Abre el '
                                  'enlace del correo y vuelve a intentarlo.';
                      }),
                child: const Text('Ya lo verifiqué'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
