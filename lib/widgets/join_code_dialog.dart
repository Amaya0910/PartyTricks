import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:party_tricks/services/rooms/room_code_generator.dart';
import 'package:party_tricks/widgets/blurred_dialog.dart';
import 'package:party_tricks/widgets/code_tiles.dart';
import 'package:party_tricks/widgets/party_pill.dart';

/// Pide un código de 6 caracteres. Devuelve el código o null si se cierra.
///
/// Sirve para entrar a una sala privada y para agregar amigos: los códigos
/// de sala y de amistad usan el mismo alfabeto y el mismo largo.
class JoinCodeDialog extends StatefulWidget {
  const JoinCodeDialog({
    super.key,
    this.title = 'Ingresar',
    this.label = 'Ingresa Codigo',
  });

  final String title;
  final String label;

  static Future<String?> show(
    BuildContext context, {
    String title = 'Ingresar',
    String label = 'Ingresa Codigo',
  }) {
    return showBlurredDialog<String>(
      context,
      builder: (_) => JoinCodeDialog(title: title, label: label),
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
      title: widget.title,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PartyPill(label: widget.label),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _focus.requestFocus,
              child: Stack(
                children: [
                  CodeTiles(
                    text: _controller.text,
                    length: RoomCodeGenerator.length,
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
                            (old, value) =>
                                value.copyWith(text: value.text.toUpperCase()),
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
