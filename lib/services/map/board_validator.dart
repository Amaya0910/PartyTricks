import 'package:party_tricks/models/map/board_map.dart';
import 'package:party_tricks/services/game_engine/board_layout.dart';

/// Qué tipo de problema tiene un tablero.
enum BoardProblemKind {
  /// El tablero no tiene casillas.
  empty,

  /// El id no coincide con su posición en la lista (el motor busca las
  /// casillas por posición).
  idOutOfOrder,

  /// La casilla [BoardLayout.startId] no es de tipo salida.
  missingStart,

  /// Hay una salida que no es la casilla [BoardLayout.startId].
  extraStart,

  /// La casilla no lleva a ninguna parte.
  deadEnd,

  /// `next` apunta a una casilla que no existe.
  invalidNext,

  /// `next` apunta a la misma casilla.
  selfLoop,

  /// `next` repite una casilla.
  repeatedNext,

  /// Más de dos caminos: el motor y las estadísticas solo conocen el
  /// principal (0) y el atajo (1).
  tooManyBranches,

  /// No se llega a la casilla desde la salida.
  unreachable,

  /// Desde la casilla no se puede volver a la salida: el jugador quedaría
  /// dando vueltas en un ciclo que no pasa por ella.
  noWayBack,

  /// La casilla no está dibujada en el mapa.
  missingVisual,

  /// El mapa tiene una plataforma con un id que el tablero no tiene.
  orphanVisual,
}

class BoardProblem {
  const BoardProblem(this.kind, this.message, {this.tileId});

  final BoardProblemKind kind;
  final String message;

  /// La casilla con el problema, si es de una sola.
  final int? tileId;

  @override
  String toString() => message;
}

/// Revisa que [board] se pueda jugar y, si se pasa [map], que el dibujo
/// tenga exactamente las mismas casillas. Devuelve la lista de problemas;
/// vacía si todo está bien.
List<BoardProblem> validateBoard(BoardLayout board, {BoardMap? map}) {
  final tiles = board.tiles;
  if (tiles.isEmpty) {
    return const [
      BoardProblem(BoardProblemKind.empty, 'El tablero está vacío.'),
    ];
  }
  final problems = <BoardProblem>[];
  void add(BoardProblemKind kind, String message, {int? tileId}) =>
      problems.add(BoardProblem(kind, message, tileId: tileId));

  for (final (index, tile) in tiles.indexed) {
    if (tile.id != index) {
      add(
        BoardProblemKind.idOutOfOrder,
        'En la posición $index está la casilla ${tile.id}: los ids tienen '
        'que ir seguidos desde 0.',
        tileId: tile.id,
      );
    }
  }

  const start = BoardLayout.startId;
  if (start >= tiles.length || tiles[start].type != TileType.start) {
    add(
      BoardProblemKind.missingStart,
      'La casilla $start tiene que ser la salida.',
      tileId: start,
    );
  }
  for (final (index, tile) in tiles.indexed) {
    if (index != start && tile.type == TileType.start) {
      add(
        BoardProblemKind.extraStart,
        'La casilla $index es una salida; solo puede serlo la $start.',
        tileId: index,
      );
    }
  }

  // Conexiones válidas, por posición, para revisar a dónde se llega.
  final edges = <int, List<int>>{};
  for (final (index, tile) in tiles.indexed) {
    final valid = <int>[];
    if (tile.next.isEmpty) {
      add(
        BoardProblemKind.deadEnd,
        'La casilla $index no lleva a ninguna parte.',
        tileId: index,
      );
    }
    if (tile.next.length > 2) {
      add(
        BoardProblemKind.tooManyBranches,
        'La casilla $index tiene ${tile.next.length} caminos; como mucho '
        'puede tener 2 (el principal y el atajo).',
        tileId: index,
      );
    }
    for (final next in tile.next) {
      if (next < 0 || next >= tiles.length) {
        add(
          BoardProblemKind.invalidNext,
          'La casilla $index lleva a la $next, que no existe.',
          tileId: index,
        );
      } else if (next == index) {
        add(
          BoardProblemKind.selfLoop,
          'La casilla $index lleva a sí misma.',
          tileId: index,
        );
      } else if (valid.contains(next)) {
        add(
          BoardProblemKind.repeatedNext,
          'La casilla $index lleva dos veces a la $next.',
          tileId: index,
        );
      } else {
        valid.add(next);
      }
    }
    edges[index] = valid;
  }

  if (start < tiles.length) {
    final reached = _reach(start, edges);
    for (var index = 0; index < tiles.length; index++) {
      if (!reached.contains(index)) {
        add(
          BoardProblemKind.unreachable,
          'No se llega a la casilla $index desde la salida.',
          tileId: index,
        );
      }
    }

    final backwards = <int, List<int>>{};
    for (final MapEntry(key: from, value: targets) in edges.entries) {
      for (final to in targets) {
        (backwards[to] ??= []).add(from);
      }
    }
    final returning = _reach(start, backwards);
    for (var index = 0; index < tiles.length; index++) {
      // Un callejón ya se avisó; aquí van las que tienen salida pero
      // giran en un ciclo que no pasa por la salida.
      if (!returning.contains(index) && tiles[index].next.isNotEmpty) {
        add(
          BoardProblemKind.noWayBack,
          'Desde la casilla $index no se puede volver a la salida: queda '
          'en un ciclo que no pasa por la $start.',
          tileId: index,
        );
      }
    }
  }

  if (map != null) {
    for (final id in map.missingTiles([
      for (var i = 0; i < tiles.length; i++) i,
    ])) {
      add(
        BoardProblemKind.missingVisual,
        'La casilla $id no está dibujada en el mapa (falta una plataforma '
        'con "casilla" = $id).',
        tileId: id,
      );
    }
    final orphans = [
      for (final id in map.tiles.keys)
        if (id < 0 || id >= tiles.length) id,
    ]..sort();
    for (final id in orphans) {
      add(
        BoardProblemKind.orphanVisual,
        'El mapa tiene una plataforma con "casilla" = $id, pero el tablero '
        'no tiene esa casilla.',
        tileId: id,
      );
    }
  }

  return problems;
}

/// Las casillas a las que se llega desde [from] siguiendo [edges].
Set<int> _reach(int from, Map<int, List<int>> edges) {
  final reached = <int>{from};
  final pending = [from];
  while (pending.isNotEmpty) {
    for (final next in edges[pending.removeLast()] ?? const <int>[]) {
      if (reached.add(next)) pending.add(next);
    }
  }
  return reached;
}
