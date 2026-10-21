import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:party_tricks/controllers/room_controller.dart';
import 'package:party_tricks/models/room.dart';
import 'package:party_tricks/screens/board_screen.dart';
import 'package:party_tricks/services/game/game_providers.dart';
import 'package:party_tricks/services/rooms/room_providers.dart';
import 'package:party_tricks/theme/app_colors.dart';
import 'package:party_tricks/widgets/player_slot.dart';

/// Sala de espera: muestra el código, los jugadores y la cuenta regresiva
/// de 1:30.
///
/// El teléfono del creador decide cuándo arranca o se cierra la sala.
class LobbyScreen extends ConsumerStatefulWidget {
  const LobbyScreen({super.key, required this.roomId});

  final String roomId;

  static Route<void> route(String roomId) {
    return MaterialPageRoute(builder: (_) => LobbyScreen(roomId: roomId));
  }

  @override
  ConsumerState<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends ConsumerState<LobbyScreen> {
  /// Desenfoque del fondo detrás de la sala.
  static const double _backgroundBlur = 8;

  Timer? _timer;
  bool _deciding = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _tick() {
    if (!mounted) return;
    setState(() {}); // Actualiza la cuenta regresiva.

    final room = ref.read(roomProvider(widget.roomId)).value;
    final me = ref.read(roomIdentityProvider).value;
    if (room == null || me == null || room.hostUid != me.uid) return;
    if (room.status != RoomStatus.waiting || _deciding) return;

    final decision = room.decide(DateTime.now());
    if (decision == LobbyDecision.keepWaiting) return;
    _deciding = true;
    _applyDecision(room, decision).whenComplete(() => _deciding = false);
  }

  /// Al arrancar, primero se guarda la partida y después se avisa a todos.
  Future<void> _applyDecision(Room room, LobbyDecision decision) async {
    final rooms = ref.read(roomServiceProvider);
    if (decision == LobbyDecision.close) {
      await rooms.setStatus(room, RoomStatus.closed);
      return;
    }
    await ref.read(gameServiceProvider).startGame(room);
    await rooms.setStatus(room, RoomStatus.playing);
  }

  Future<void> _leave() async {
    await ref.read(roomControllerProvider.notifier).leave(widget.roomId);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    // Cuando la sala arranca, todos pasan al tablero.
    ref.listen(roomProvider(widget.roomId), (previous, next) {
      final room = next.value;
      if (room == null || room.status != RoomStatus.playing) return;
      if (previous?.value?.status == RoomStatus.playing) return;
      final me = ref.read(roomIdentityProvider).value;
      Navigator.of(context).pushReplacement(
        BoardScreen.route(room.id, isHost: room.hostUid == me?.uid),
      );
    });
    final roomAsync = ref.watch(roomProvider(widget.roomId));
    final myUid = ref.watch(roomIdentityProvider).value?.uid;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _leave();
      },
      child: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/Fondo_Principal.png',
              fit: BoxFit.cover,
              alignment: Alignment.bottomCenter,
            ),
            // Fondo desenfocado, como en el mockup.
            ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: _backgroundBlur,
                  sigmaY: _backgroundBlur,
                ),
                child: const SizedBox.expand(),
              ),
            ),
            SafeArea(
              child: roomAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, _) => _Message(
                  text: 'No se pudo cargar la sala',
                  onBack: _leave,
                ),
                data: (room) => room == null
                    ? _Message(text: 'La sala ya no existe', onBack: _leave)
                    : _content(room, myUid),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _content(Room room, String? myUid) {
    return switch (room.status) {
      RoomStatus.waiting => _Waiting(room: room, myUid: myUid, onLeave: _leave),
      // Mientras se arma la partida, hasta que el listener pase al tablero.
      RoomStatus.playing => _Message(
        text: '¡La partida va a empezar!',
        onBack: _leave,
      ),
      RoomStatus.closed => _Message(
        text: '¡Se ha terminado el tiempo! Invita a tus amigos a jugar',
        onBack: _leave,
      ),
    };
  }
}

class _Waiting extends StatelessWidget {
  const _Waiting({
    required this.room,
    required this.myUid,
    required this.onLeave,
  });

  final Room room;
  final String? myUid;
  final VoidCallback onLeave;

  @override
  Widget build(BuildContext context) {
    final left = room.lobbyEndsAt.difference(DateTime.now());
    final seconds = left.isNegative ? 0 : left.inSeconds;
    final clock =
        '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
    final players = room.players.values.toList()
      ..sort((a, b) => a.joinedAt.compareTo(b.joinedAt));

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.tileBorder,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.blueStrong, width: 3),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.headerBorder,
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Header(clock: clock),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const _Pill(label: 'Tu código'),
                          const SizedBox(height: 8),
                          _CodePanel(code: room.code),
                          const SizedBox(height: 16),
                          _Pill(
                            label:
                                'Jugadores (${players.length}/${room.maxPlayers})'
                                ' · ${room.rounds} rondas',
                          ),
                          const SizedBox(height: 12),
                          // Un espacio por cada jugador posible; se
                          // desplaza si no caben todos.
                          Expanded(
                            child: GridView.builder(
                              itemCount: room.maxPlayers,
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 3,
                                    mainAxisSpacing: 12,
                                    crossAxisSpacing: 12,
                                    childAspectRatio: 0.8,
                                  ),
                              itemBuilder: (context, index) {
                                if (index >= players.length) {
                                  return const PlayerSlot();
                                }
                                final player = players[index];
                                return PlayerSlot(
                                  player: player,
                                  isMe: player.uid == myUid,
                                  isHost: player.uid == room.hostUid,
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              backgroundColor: AppColors.menuButton,
            ),
            onPressed: onLeave,
            child: const Text('Salir'),
          ),
        ],
      ),
    );
  }
}

/// Título azul de la tarjeta, con la cuenta regresiva debajo.
class _Header extends StatelessWidget {
  const _Header({required this.clock});

  final String clock;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.blueStrong,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          const Text(
            'Tu party',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppColors.progressText,
            ),
          ),
          Text(
            'Empieza en $clock',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.progressText,
            ),
          ),
        ],
      ),
    );
  }
}

/// Etiqueta redondeada ("Tu código", "Jugadores").
class _Pill extends StatelessWidget {
  const _Pill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.menuButton,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.progressText,
          ),
        ),
      ),
    );
  }
}

/// Código de la sala en cuadritos, con un guion en medio (ABC-234).
class _CodePanel extends StatelessWidget {
  const _CodePanel({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    final half = code.length ~/ 2;
    final chars = code.split('');
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.lobbyCodePanel,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          for (var i = 0; i < chars.length; i++) ...[
            if (i == half)
              const SizedBox(
                width: 16,
                child: Text(
                  '-',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
            Expanded(child: _Digit(char: chars[i])),
          ],
        ],
      ),
    );
  }
}

class _Digit extends StatelessWidget {
  const _Digit({required this.char});

  final String char;

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

class _Message extends StatelessWidget {
  const _Message({required this.text, required this.onBack});

  final String text;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.menuButton,
              ),
              onPressed: onBack,
              child: const Text('Regresar a menú'),
            ),
          ],
        ),
      ),
    );
  }
}