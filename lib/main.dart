import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:party_tricks/screens/main_shell_screen.dart';
import 'package:party_tricks/theme/app_theme.dart';

void main() {
  runApp(const ProviderScope(child: PartyTricksApp()));
}

class PartyTricksApp extends StatelessWidget {
  const PartyTricksApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Party Tricks',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const MainShellScreen(),
    );
  }
}