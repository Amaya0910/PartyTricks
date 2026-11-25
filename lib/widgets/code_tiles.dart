import 'package:flutter/material.dart';
import 'package:party_tricks/theme/app_colors.dart';
import 'package:party_tricks/widgets/fx/pop_in.dart';

/// Un código de sala en cuadritos, con un guion en medio (ABC-234).
///
/// Cada letra nueva entra con un rebote. Lo usan la sala de espera (para
/// mostrar el código) y el diálogo para escribirlo. Solo dibuja.
class CodeTiles extends StatelessWidget {
  const CodeTiles({
    super.key,
    required this.text,
    required this.length,
    this.activeIndex = -1,
    this.animateIn = false,
  });

  /// Lo escrito hasta ahora (puede ser más corto que [length]).
  final String text;
  final int length;

  /// Cuadrito donde va el siguiente carácter (-1 si no hay ninguno).
  final int activeIndex;

  /// Si los cuadritos entran uno detrás de otro al aparecer.
  final bool animateIn;

  @override
  Widget build(BuildContext context) {
    final half = length ~/ 2;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.lobbyCodePanel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.slotBorder, width: 2),
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
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                ),
              ),
            Expanded(child: _tile(i)),
          ],
        ],
      ),
    );
  }

  Widget _tile(int i) {
    final tile = _Tile(
      char: i < text.length ? text[i] : '',
      isActive: i == activeIndex,
    );
    return animateIn ? PopIn.staggered(index: i, child: tile) : tile;
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.char, required this.isActive});

  final String char;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: AnimatedScale(
        scale: isActive ? 1.08 : 1,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutBack,
        child: AspectRatio(
          aspectRatio: 0.7,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isActive ? AppColors.blueStrong : AppColors.white,
                width: 2,
              ),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.slotBorder,
                  blurRadius: 0,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Center(
              child: FittedBox(
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  // Cada letra nueva cae con un rebote.
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 260),
                    transitionBuilder: (child, animation) => ScaleTransition(
                      scale: CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOutBack,
                      ),
                      child: child,
                    ),
                    child: Text(
                      char,
                      key: ValueKey(char),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
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
