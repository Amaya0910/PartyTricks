import 'package:flutter/material.dart';
import 'package:party_tricks/theme/app_colors.dart';
import 'package:party_tricks/theme/party_page_transitions.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    // La letra del mockup en toda la app (antes solo algunas pantallas).
    fontFamily: 'Inter',
    colorScheme: ColorScheme.fromSeed(seedColor: AppColors.inactiveButton),
    scaffoldBackgroundColor: AppColors.screenBackground,
    // Las pantallas entran creciendo con un rebote.
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: PartyPageTransitionsBuilder(),
        TargetPlatform.iOS: PartyPageTransitionsBuilder(),
        TargetPlatform.windows: PartyPageTransitionsBuilder(),
        TargetPlatform.macOS: PartyPageTransitionsBuilder(),
        TargetPlatform.linux: PartyPageTransitionsBuilder(),
      },
    ),
    // Avisos de abajo: burbujas flotantes con borde blanco, no la barra gris.
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.headerBorder,
      elevation: 6,
      insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppColors.white, width: 2),
      ),
      contentTextStyle: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: AppColors.white,
      ),
      actionTextColor: AppColors.pillBackground,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.inactiveButton,
      indicatorColor: AppColors.activeButton,
      iconTheme: WidgetStateProperty.all(
        const IconThemeData(color: AppColors.navigationContent),
      ),
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(
          color: AppColors.navigationContent,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}
