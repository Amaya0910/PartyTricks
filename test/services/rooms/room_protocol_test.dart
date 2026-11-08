import 'package:flutter_test/flutter_test.dart';
import 'package:party_tricks/models/app_protocol.dart';
import 'package:party_tricks/models/room.dart';
import 'package:party_tricks/services/map/map_catalog.dart';
import 'package:party_tricks/services/rooms/room_protocol.dart';

void main() {
  test('una sala de mapa_01 la puede jugar la 1.0.0', () {
    expect(
      requiredProtocolFor(RoomSettings(isPublic: true)),
      AppProtocol.legacy,
    );
  });

  test('el protocolo de la sala sale de lo que usa', () {
    final settings = RoomSettings(isPublic: true);
    expect(
      requiredProtocolFor(settings),
      AppProtocol.requiredFor(featuresOf(settings)),
    );
    expect(featuresOf(settings), contains(MapCatalog.mapa01));
  });

  test('un mapa que no existe no arma sala', () {
    expect(
      () => requiredProtocolFor(RoomSettings(isPublic: true, mapId: 'mapa_99')),
      throwsA(isA<UnknownMapException>()),
    );
  });

  group('listas públicas', () {
    test('las salas que juega la 1.0.0 siguen en publicLobby', () {
      expect(publicLobbyFor(AppProtocol.legacy), 'publicLobby');
    });

    test('las que piden más van en su propia lista', () {
      expect(publicLobbyFor(3), 'publicLobbyByProtocol/3');
      expect(publicLobbyFor(12), 'publicLobbyByProtocol/12');
    });

    test('esta versión lee todas las que puede jugar, sin repetir', () {
      final lobbies = playablePublicLobbies();

      expect(lobbies.first, publicLobbyFor(AppProtocol.current));
      expect(lobbies.last, 'publicLobby');
      expect(lobbies.toSet().length, lobbies.length);
      expect(lobbies, isNot(contains(publicLobbyFor(AppProtocol.current + 1))));
    });
  });
}
