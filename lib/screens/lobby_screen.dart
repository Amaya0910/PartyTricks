import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:party_tricks/controllers/room_controller.dart';
import 'package:party_tricks/models/room.dart';
import 'package:party_tricks/services/rooms/room_providers.dart';
import 'package:party_tricks/theme/app_colors.dart';

/// Sala de espera: muestra los jugadores y la cuenta regresiva de 1:30.
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
    final status = decision == LobbyDecision.start
        ? RoomStatus.playing
        : RoomStatus.closed;
    ref
        .read(roomServiceProvider)
        .setStatus(room, status)
        .whenComplete(() => _deciding = false);
  }

  Future<void> _leave() async {
    await ref.read(roomControllerProvider.notifier).leave(widget.roomId);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final roomAsync = ref.watch(roomProvider(widget.roomId));
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _leave();
      },
      child: Scaffold(
        backgroundColor: AppColors.screenBackground,
        appBar: AppBar(
          title: const Text('Sala de espera'),
          automaticallyImplyLeading: false,
        ),
        body: SafeArea(
          child: roomAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) =>
                _Message(text: 'No se pudo cargar la sala', onBack: _leave),
            data: (room) => room == null
                ? _Message(text: 'La sala ya no existe', onBack: _leave)
                : _content(room),
          ),
        ),
      ),
    );
  }

  Widget _content(Room room) {
    return switch (room.status) {
      RoomStatus.waiting => _Waiting(room: room, onLeave: _leave),
      // Provisional: el tablero llega en feature/board-turns.
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
  const _Waiting({required this.room, required this.onLeave});

  final Room room;
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
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            room.isPublic ? 'Sala pública' : 'Código: ${room.code}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            clock,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            'Jugadores (${players.length}/${room.maxPlayers}) · '
            '${room.rounds} rondas',
            style: const TextStyle(fontSize: 18),
          ),
          Expanded(
            child: ListView(
              children: [
                for (final player in players)
                  ListTile(
                    leading: Icon(
                      player.uid == room.hostUid ? Icons.star : Icons.person,
                    ),
                    title: Text(player.username),
                  ),
              ],
            ),
          ),
          OutlinedButton(onPressed: onLeave, child: const Text('Salir')),
        ],
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
