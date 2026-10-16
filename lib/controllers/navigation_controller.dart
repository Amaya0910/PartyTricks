import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:party_tricks/models/app_section.dart';

/// Guarda qué sección está seleccionada en la barra de navegación.
class NavigationController extends Notifier<AppSection> {
  @override
  AppSection build() => AppSection.home;

  void select(AppSection section) => state = section;
}

final navigationControllerProvider =
    NotifierProvider<NavigationController, AppSection>(
  NavigationController.new,
);

