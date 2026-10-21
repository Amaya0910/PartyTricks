import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:party_tricks/services/rooms/room_code_generator.dart';
import 'package:party_tricks/theme/app_colors.dart';
import 'package:party_tricks/widgets/blurred_dialog.dart';

/// Pide el código de una sala privada. Devuelve el código o null si se cierra.
class JoinCodeDialog extends StatefulWidget {
  const JoinCodeDialog({super.key});

  static Future<String?> show(BuildContext context) {
    return showBlurredDialog<String>(
      context,
      builder: (_) => const JoinCodeDialog(),
    );
  }

  @override
  State<JoinCodeDialog> createState() => _JoinCodeDialogState();
}

class _JoinCodeDialogState extends State<JoinCodeDialog> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChanged);
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onChanged() {
    setState(() {});
    if (_controller.text.length == RoomCodeGenerator.length) _submit();
  }

  void _submit() {
    if (_done || _controller.text.length != RoomCodeGenerator.length) return;
    _done = true;
    Navigator.of(context).pop(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    return DialogCard(
      title: 'Ingresar',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _Pill(label: 'Ingresa Codigo'),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _focus.requestFocus,
              child: Stack(
                children: [
                  _CodePanel(
                    text: _controller.text,
                    activeIndex: _focus.hasFocus ? _controller.text.length : -1,
                  ),
                  // Campo real e invisible: recibe el teclado y el pegado.
                  Positioned.fill(
                    child: Opacity(
                      opacity: 0,
                      child: TextField(
                        controller: _controller,
                        focusNode: _focus,
                        autofocus: true,
                        autocorrect: false,
                        enableSuggestions: false,
                        textCapitalization: TextCapitalization.characters,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _submit(),
                        inputFormatters: [
                          TextInputFormatter.withFunction(
                            (old, value) => value.copyWith(
                              text: value.text.toUpperCase(),
                            ),
                          ),
                          // Solo el alfabeto de los códigos (sin O/0 ni I/1).
                          FilteringTextInputFormatter.allow(
                            RegExp('[${RoomCodeGenerator.alphabet}]'),
                          ),
                          LengthLimitingTextInputFormatter(
                            RoomCodeGenerator.length,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Etiqueta redondeada "Ingresa Codigo".
class _Pill extends StatelessWidget {
  const _Pill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.menuButton,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: AppColors.slotBorder,
              blurRadius: 3,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.progressText,
          ),
        ),
      ),
    );
  }
}

/// Los 6 cuadritos con un guion en medio (ABC-234).
class _CodePanel extends StatelessWidget {
  const _CodePanel({required this.text, required this.activeIndex});

  final String text;

  /// Cuadrito donde se escribirá el siguiente carácter (-1 si no hay foco).
  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    const length = RoomCodeGenerator.length;
    const half = length ~/ 2;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.lobbyCodePanel,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          for (var i = 0; i < length; i++) ...[
            if (i == half)
              const SizedBox(
                width: 16,
                child: Text(
                  '-',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
            Expanded(
              child: _Digit(
                char: i < text.length ? text[i] : '',
                isActive: i == activeIndex,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Digit extends StatelessWidget {
  const _Digit({required this.char, required this.isActive});

  final String char;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: AspectRatio(
        aspectRatio: 0.7,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.tileBorder,
            borderRadius: BorderRadius.circular(6),
            border: isActive
                ? Border.all(color: AppColors.blueStrong, width: 2)
                : null,
            boxShadow: const [
              BoxShadow(
                color: AppColors.slotBorder,
                blurRadius: 2,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: FittedBox(
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Text(
                  char,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}