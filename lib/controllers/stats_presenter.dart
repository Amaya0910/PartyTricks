import 'package:party_tricks/models/chest.dart';
import 'package:party_tricks/models/player_stats.dart';
import 'package:party_tricks/models/stats/stats_section.dart';
import 'package:party_tricks/services/stats/stats_format.dart';

/// Convierte las estadísticas en las tarjetas de la pantalla Stats, en orden.
///
/// Las tres primeras son las del mockup (Partidas, Minijuegos y Tiempo); las
/// demás alternan los mismos tres colores. Las etiquetas y el formato viven
/// aquí para que la pantalla solo dibuje.
class StatsPresenter {
  const StatsPresenter();

  List<StatsSection> sections(PlayerStats stats) => [
    _matches(stats),
    _minigames(stats),
    _time(stats),
    _podium(stats),
    _awards(stats),
    _matchDetails(stats),
    _board(stats),
    _minigameTypes(stats),
    _shop(stats),
    _social(stats),
  ];

  StatsSection _matches(PlayerStats stats) {
    final m = stats.matches;
    return StatsSection(
      title: 'Partidas',
      tone: StatsTone.blue,
      rows: [
        StatsRow('Ganadas:', '${m.won}'),
        StatsRow('Perdidas:', '${m.lost}'),
        StatsRow('Porcentaje de ganadas:', StatsFormat.percent(m.winRate)),
        StatsRow('Max. diamantes en una partida:', '${m.maxDiamonds}'),
        StatsRow('Max. monedas en una partida:', '${m.maxCoins}'),
      ],
    );
  }

  StatsSection _minigames(PlayerStats stats) {
    final m = stats.minigames;
    return StatsSection(
      title: 'Minijuegos',
      tone: StatsTone.darkBlue,
      rows: [
        StatsRow('Ganados:', '${m.won}'),
        StatsRow('Perdidos:', '${m.lost}'),
        StatsRow('Porcentaje de ganadas:', StatsFormat.percent(m.winRate)),
        StatsRow('Max. ganados en una partida:', '${m.maxWonInMatch}'),
        StatsRow('Max. puntaje en un minijuego:', '${m.bestScore}'),
      ],
    );
  }

  StatsSection _time(PlayerStats stats) {
    final t = stats.time;
    return StatsSection(
      title: 'Tiempo',
      tone: StatsTone.purple,
      rows: [
        StatsRow('En la app:', StatsFormat.minutes(t.secondsInApp)),
        StatsRow('Jugando:', StatsFormat.minutes(t.secondsPlaying)),
        StatsRow('En minijuegos:', StatsFormat.minutes(t.secondsInMinigames)),
        StatsRow('Racha actual:', StatsFormat.days(t.currentStreak)),
        StatsRow('Racha máxima:', StatsFormat.days(t.maxStreak)),
      ],
    );
  }

  StatsSection _podium(PlayerStats stats) {
    final m = stats.matches;
    return StatsSection(
      title: 'Podio',
      tone: StatsTone.blue,
      rows: [
        StatsRow('Partidas jugadas:', '${m.played}'),
        StatsRow('Primer lugar:', '${m.firstPlaces}'),
        StatsRow('Segundo lugar:', '${m.secondPlaces}'),
        StatsRow('Tercer lugar:', '${m.thirdPlaces}'),
        StatsRow('Empates:', '${m.ties}'),
        StatsRow('Victorias seguidas:', '${m.currentWinStreak}'),
        StatsRow('Max. victorias seguidas:', '${m.maxWinStreak}'),
      ],
    );
  }

  StatsSection _awards(PlayerStats stats) {
    final a = stats.awards;
    return StatsSection(
      title: 'Premios finales',
      tone: StatsTone.darkBlue,
      rows: [
        StatsRow('Rey de los minijuegos:', '${a.minigames}'),
        StatsRow('Peor suerte:', '${a.worstLuck}'),
        StatsRow('El más rico:', '${a.richest}'),
        StatsRow('Mayor comprador:', '${a.topBuyer}'),
        StatsRow('Total de premios:', '${a.total}'),
      ],
    );
  }

  StatsSection _matchDetails(PlayerStats stats) {
    final m = stats.matches;
    return StatsSection(
      title: 'Detalle de partidas',
      tone: StatsTone.purple,
      rows: [
        StatsRow('Como anfitrión:', '${m.hosted}'),
        StatsRow('Públicas:', '${m.publicMatches}'),
        StatsRow('Privadas:', '${m.privateMatches}'),
        StatsRow('Rondas jugadas:', '${m.roundsPlayed}'),
        StatsRow(
          'Partida más larga:',
          StatsFormat.minutes(m.longestMatchSeconds),
        ),
        StatsRow(
          'Promedio de diamantes:',
          StatsFormat.decimal(m.averageDiamonds),
        ),
        StatsRow('Monedas ganadas:', '${stats.totalCoinsEarned}'),
        StatsRow('Diamantes ganados:', '${m.totalDiamonds}'),
      ],
    );
  }

  StatsSection _board(PlayerStats stats) {
    final b = stats.board;
    return StatsSection(
      title: 'Tablero',
      tone: StatsTone.blue,
      rows: [
        StatsRow('Dados lanzados:', '${b.diceRolled}'),
        StatsRow('Promedio del dado:', StatsFormat.decimal(b.averageRoll)),
        StatsRow('Veces con el número máximo:', '${b.maxRolls}'),
        StatsRow('Casillas positivas:', '${b.positiveTiles}'),
        StatsRow('Casillas negativas:', '${b.negativeTiles}'),
        StatsRow('Casillas especiales:', '${b.specialTiles}'),
        StatsRow('Caminos normales:', '${b.mainPathsTaken}'),
        StatsRow('Atajos:', '${b.shortcutsTaken}'),
        StatsRow('Vueltas completas:', '${b.laps}'),
        StatsRow('Diamantes del mapa:', '${b.mapDiamonds}'),
        StatsRow('Compras en tiendas del mapa:', '${b.shopPurchases}'),
      ],
    );
  }

  StatsSection _minigameTypes(PlayerStats stats) {
    final m = stats.minigames;
    return StatsSection(
      title: 'Minijuegos por tipo',
      tone: StatsTone.darkBlue,
      rows: [
        StatsRow('Favorito:', StatsFormat.text(m.favoriteType)),
        StatsRow('Más ganado:', StatsFormat.text(m.mostWonType)),
        StatsRow('Tipos jugados:', '${m.typesPlayed}'),
      ],
    );
  }

  StatsSection _shop(PlayerStats stats) {
    final s = stats.shop;
    return StatsSection(
      title: 'Tienda',
      tone: StatsTone.purple,
      rows: [
        for (final chest in ChestType.values)
          StatsRow('${chest.title}:', '${s.opened(chest)}'),
        StatsRow('Total de cofres:', '${s.totalChests}'),
        StatsRow('Diamantes gastados:', '${s.diamondsSpent}'),
        StatsRow('Cosméticos obtenidos:', '${s.cosmeticPrizes}'),
        StatsRow('Dados extra obtenidos:', '${s.dicePrizes}'),
        StatsRow('Premios de monedas:', '${s.coinPrizes}'),
        StatsRow('Cofres vacíos:', '${s.emptyPrizes}'),
        StatsRow('Monedas de cofres:', '${s.coinsFromChests}'),
      ],
    );
  }

  StatsSection _social(PlayerStats stats) {
    final s = stats.social;
    return StatsSection(
      title: 'Social',
      tone: StatsTone.blue,
      rows: [
        StatsRow(
          'Compañero más frecuente:',
          StatsFormat.text(s.favoritePartner?.username),
        ),
        StatsRow('Partidas con amigos:', '${s.matchesWithFriends}'),
        StatsRow('Invitaciones enviadas:', '${s.invitesSent}'),
        StatsRow('Invitaciones aceptadas:', '${s.invitesAccepted}'),
        StatsRow('Mensajes enviados:', '${s.messagesSent}'),
      ],
    );
  }
}
