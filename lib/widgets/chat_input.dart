import 'package:flutter/material.dart';
import 'package:party_tricks/models/social/chat_message.dart';
import 'package:party_tricks/theme/app_colors.dart';
import 'package:party_tricks/widgets/fx/chunky_button.dart';

/// Campo para escribir del chat ("Presiona para escribir") con el botón de
/// enviar. Limita el mensaje a [ChatMessage.maxLength] caracteres.
class ChatInput extends StatefulWidget {
  const ChatInput({super.key, required this.onSend, this.enabled = true});

  /// Devuelve true si se envió, para limpiar el campo.
  final Future<bool> Function(String text) onSend;
  final bool enabled;

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  final _controller = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_sending || _controller.text.trim().isEmpty) return;
    setState(() => _sending = true);
    final sent = await widget.onSend(_controller.text);
    if (!mounted) return;
    setState(() => _sending = false);
    if (sent) _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.chatField,
      padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              enabled: widget.enabled,
              maxLength: ChatMessage.maxLength,
              minLines: 1,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(),
              decoration: const InputDecoration(
                hintText: 'Presiona para escribir',
                border: InputBorder.none,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 4, left: 4, right: 4),
            child: Tooltip(
              message: 'Enviar',
              child: ChunkyButton(
                color: AppColors.friendsAccent,
                edgeColor: AppColors.friendsBorder,
                radius: 22,
                depth: 4,
                padding: const EdgeInsets.all(10),
                semanticLabel: 'Enviar',
                onPressed: widget.enabled && !_sending ? _send : null,
                child: const Icon(
                  Icons.send_rounded,
                  size: 22,
                  color: AppColors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
