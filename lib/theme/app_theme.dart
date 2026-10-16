import 'package:flutter/material.dart';
import 'package:party_tricks/theme/app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.inactiveButton),
        scaffoldBackgroundColor: AppColors.screenBackground,
        navigationBarTheme: _navigationBarTheme,
      );

  static NavigationBarThemeData get _navigationBarTheme =>
      NavigationBarThemeData(
        backgroundColor: AppColors.inactiveButton,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.activeButton,
        iconTheme: WidgetStateProperty.all(
          const IconThemeData(color: AppColors.navigationContent),
        ),
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(
            color: AppColors.navigationContent,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
}