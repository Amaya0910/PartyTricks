import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:party_tricks/controllers/invite_controller.dart';
import 'package:party_tricks/controllers/room_controller.dart';
import 'package:party_tricks/controllers/room_guard.dart';
import 'package:party_tricks/models/room.dart';
import 'package:party_tricks/screens/board_screen.dart';
import 'package:party_tricks/services/game/game_providers.dart';
import 'package:party_tricks/services/map/map_catalog.dart';
import 'package:party_tricks/services/rooms/room_providers.dart';
import 'package:party_tricks/services/social/social_exception.dart';
import 'package:party_tricks/theme/app_colors.dart';
import 'package:party_tricks/widgets/app_background.dart';
import 'package:party_tricks/widgets/code_tiles.dart';
import 'package:party_tricks/widgets/fx/idle_motion.dart';
import 'package:party_tricks/widgets/fx/party_button.dart';
import 'package:party_tricks/widgets/fx/pop_in.dart';
import 'package:party_tricks/widgets/invite_friends_dialog.dart';
import 'package:party_tricks/widgets/party_pill.dart';
import 'package:party_tricks/widgets/player_slot.dart';

/// Sala de espera: muestra el código, los jugadores y la cuenta regresiva
/// de 1:30.
///
/// El teléfono del anfitrión decide cuándo arranca o se cierra la sala. Si
/// el anfitrión se va, otro jugador toma su lugar ([RoomGuard]) y sigue la
/// cuenta regresiva.
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

  /// Presencia y cambio de anfitrión mientras se espera.
  RoomGuard? _guard;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    ref.listenManual(roomIdentityProvider, (_, next) {
      final uid = next.value?.uid;
      if (uid == null || _guard != null) return;
      _guard = RoomGuard(
        roomId: widget.roomId,
        uid: uid,
        rooms: ref.read(roomServiceProvider),
        presence: ref.read(presenceServiceProvider),
        policy: ref.read(disconnectionPolicyProvider),
      )..start();
      _guard!.update(room: ref.read(roomProvider(widget.roomId)).value);
    }, fireImmediately: true);
    ref.listenManual(
      roomProvider(widget.roomId),
      (_, next) => _guard?.update(room: next.value),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _guard?.dispose();
    super.dispose();
  }

  void _tick() {
    if (!mounted) return;
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

  /// Abre la lista de amigos y les envía la invitación (al chat y como
  /// aviso). Los que ya están en la sala no aparecen en la lista.
  Future<void> _invite(Room room) async {
    final invites = ref.read(inviteControllerProvider);
    final messenger = ScaffoldMessenger.of(context);
    final chosen = await InviteFriendsDialog.show(
      context,
      exclude: room.players.keys.toSet(),
    );
    if (chosen == null || chosen.isEmpty) return;
    try {
      final sent = await invites.invite(room: room, friendUids: chosen);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            sent == 1 ? 'Invitación enviada' : 'Invitaciones enviadas: $sent',
          ),
        ),
      );
    } on SocialException catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(error.message)));
    }
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
            const AppBackground(),
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
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.white),
                ),
                error: (_, _) =>
                    _Message(text: 'No se pudo cargar la sala', onBack: _leave),
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
      RoomStatus.waiting => _Waiting(
        room: room,
        myUid: myUid,
        onInvite: () => _invite(room),
        onLeave: _leave,
      ),
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
    required this.onInvite,
    required this.onLeave,
  });

  final Room room;
  final String? myUid;
  final VoidCallback onInvite;
  final VoidCallback onLeave;

  @override
  Widget build(BuildContext context) {
    final players = room.players.values.toList()
      ..sort((a, b) => a.joinedAt.compareTo(b.joinedAt));

    // La tarjeta mide lo que mide su contenido y queda centrada. Si la
    // pantalla es muy pequeña, todo se desplaza en vez de desbordarse.
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    PopIn(
                      startScale: 0.7,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: AppColors.blueStrong,
                            width: 3,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: AppColors.headerBorder,
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _Header(endsAt: room.lobbyEndsAt),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                12,
                                12,
                                12,
                                12,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const PartyPill(label: 'Tu código'),
                                  const SizedBox(height: 8),
                                  CodeTiles(
                                    text: room.code,
                                    length: room.code.length,
                                    animateIn: true,
                                  ),
                                  const SizedBox(height: 16),
                                  PartyPill(
                                    label:
                                        'Jugadores (${players.length}/${room.maxPlayers})'
                                        ' · ${room.rounds} rondas'
                                        ' · ${_mapName(room.mapId)}',
                                  ),
                                  const SizedBox(height: 12),
                                  // Un espacio por cada jugador posible. La
                                  // cuadrícula mide lo que miden sus filas.
                                  GridView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    padding: EdgeInsets.zero,
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
                                      // Quien llega entra con un rebote.
                                      return PopIn(
                                        key: ValueKey(player.uid),
                                        startScale: 0.5,
                                        from: Offset.zero,
                                        child: PlayerSlot(
                                          player: player,
                                          isMe: player.uid == myUid,
                                          isHost: player.uid == room.hostUid,
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    PopIn(
                      delay: const Duration(milliseconds: 250),
                      child: PartyButton(
                        label: 'Invitar a amigos',
                        icon: Icons.person_add_rounded,
                        color: AppColors.accept,
                        edgeColor: AppColors.inactiveButton,
                        onPressed: onInvite,
                      ),
                    ),
                    const SizedBox(height: 10),
                    PopIn(
                      delay: const Duration(milliseconds: 330),
                      child: PartyButton(
                        label: 'Salir',
                        icon: Icons.logout_rounded,
                        onPressed: onLeave,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Título azul de la tarjeta, con la cuenta regresiva debajo.
class _Header extends StatelessWidget {
  const _Header({required this.endsAt});

  final DateTime endsAt;

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
              fontWeight: FontWeight.w900,
              color: AppColors.white,
              shadows: [
                Shadow(color: AppColors.headerBorder, offset: Offset(0, 3)),
              ],
            ),
          ),
          const SizedBox(height: 4),
          _Countdown(endsAt: endsAt),
        ],
      ),
    );
  }
}

/// Cuenta regresiva de la sala. Lleva su propio reloj para que cada segundo
/// se redibuje solo este texto y no toda la pantalla.
class _Countdown extends StatefulWidget {
  const _Countdown({required this.endsAt});

  final DateTime endsAt;

  @override
  State<_Countdown> createState() => _CountdownState();
}

class _CountdownState extends State<_Countdown> {
  /// Desde cuántos segundos el reloj salta más fuerte.
  static const int _hurrySeconds = 10;

  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final left = widget.endsAt.difference(DateTime.now());
    final seconds = left.isNegative ? 0 : left.inSeconds;
    final clock =
        '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
    // En los últimos segundos el reloj late para meter prisa.
    final hurry = seconds > 0 && seconds <= _hurrySeconds;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.headerPanel,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.timer_rounded, size: 18, color: AppColors.white),
          const SizedBox(width: 6),
          // Cada segundo, el número nuevo entra con un saltito.
          TweenAnimationBuilder<double>(
            key: ValueKey(seconds),
            tween: Tween(begin: hurry ? 1.35 : 1.12, end: 1),
            duration: const Duration(milliseconds: 380),
            curve: Curves.easeOutBack,
            builder: (context, scale, child) =>
                Transform.scale(scale: scale, child: child),
            child: Text(
              'Empieza en $clock',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: AppColors.white,
              ),
            ),
          ),
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
        child: PopIn(
          startScale: 0.7,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Floating(
                child: Icon(
                  Icons.celebration_rounded,
                  size: 64,
                  color: AppColors.white,
                  shadows: [
                    Shadow(color: AppColors.headerBorder, offset: Offset(0, 3)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                text,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: AppColors.white,
                  shadows: [
                    Shadow(color: AppColors.headerBorder, offset: Offset(0, 3)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: 260,
                child: PartyButton(label: 'Regresar a menú', onPressed: onBack),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// El nombre del mapa de la sala, o su id si esta versión no lo conoce.
String _mapName(String mapId) => MapCatalog.byId(mapId)?.name ?? mapId;
