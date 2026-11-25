import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:party_tricks/services/feedback/haptics.dart';
import 'package:party_tricks/theme/app_colors.dart';
import 'package:party_tricks/widgets/fx/chunky_button.dart';

/// Cuenta lo que se pidió vibrar.
class _RecordingHaptics extends Haptics {
  final calls = <String>[];

  @override
  void tap() => calls.add('tap');

  @override
  void select() => calls.add('select');

  @override
  void success() => calls.add('success');

  @override
  void error() => calls.add('error');
}

void main() {
  Future<void> pumpButton(
    WidgetTester tester, {
    Haptics? haptics,
    VoidCallback? onPressed,
  }) async {
    final button = MaterialApp(
      home: Scaffold(
        body: Center(
          child: ChunkyButton(
            color: AppColors.authAccent,
            onPressed: onPressed,
            child: const Text('Jugar'),
          ),
        ),
      ),
    );
    await tester.pumpWidget(
      haptics == null ? button : HapticsScope(haptics: haptics, child: button),
    );
  }

  testWidgets('el botón con relieve vibra al presionarlo', (tester) async {
    final haptics = _RecordingHaptics();
    var pressed = 0;
    await pumpButton(tester, haptics: haptics, onPressed: () => pressed++);

    await tester.tap(find.text('Jugar'));
    await tester.pumpAndSettle();

    expect(pressed, 1);
    expect(haptics.calls, ['tap']);
  });

  testWidgets('un botón apagado no vibra', (tester) async {
    final haptics = _RecordingHaptics();
    await pumpButton(tester, haptics: haptics);

    await tester.tap(find.text('Jugar'));
    await tester.pumpAndSettle();

    expect(haptics.calls, isEmpty);
  });

  testWidgets('sin HapticsScope no vibra ni falla', (tester) async {
    var pressed = 0;
    await pumpButton(tester, onPressed: () => pressed++);

    await tester.tap(find.text('Jugar'));
    await tester.pumpAndSettle();

    expect(pressed, 1);
  });
}
