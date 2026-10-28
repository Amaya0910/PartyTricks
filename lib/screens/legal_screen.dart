import 'package:flutter/material.dart';
import 'package:party_tricks/models/legal_document.dart';
import 'package:party_tricks/theme/app_colors.dart';

/// Muestra un texto de "Más opciones": Acerca de, Términos y condiciones o
/// Política de privacidad.
class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key, required this.document});

  final LegalDocument document;

  static Route<void> route(LegalDocument document) {
    return MaterialPageRoute(
      builder: (_) => LegalScreen(document: document),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: Text(document.title),
        backgroundColor: AppColors.settingsAccent,
        foregroundColor: AppColors.white,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            for (final section in document.sections) ...[
              Text(
                section.heading,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.settingsAccent,
                ),
              ),
              const SizedBox(height: 6),
              for (final paragraph in section.paragraphs)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    paragraph,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.4,
                      color: AppColors.authText,
                    ),
                  ),
                ),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}
