import 'package:flutter_test/flutter_test.dart';
import 'package:party_tricks/models/user_profile.dart';

void main() {
  const profile = UserProfile(
    uid: 'uid-1',
    email: 'tay@correo.com',
    username: 'Tay_01',
    friendCode: 'ABC234',
    experience: 120,
    coins: 50,
    diamonds: 3,
  );

  test('toMap y fromMap son inversos (el uid va aparte)', () {
    final map = profile.toMap();
    final copy = UserProfile.fromMap('uid-1', map);

    expect(map.containsKey('uid'), isFalse);
    expect(copy.uid, profile.uid);
    expect(copy.email, profile.email);
    expect(copy.username, profile.username);
    expect(copy.friendCode, profile.friendCode);
    expect(copy.experience, profile.experience);
    expect(copy.coins, profile.coins);
    expect(copy.diamonds, profile.diamonds);
  });

  test('fromMap usa valores por defecto si faltan campos', () {
    final copy = UserProfile.fromMap('uid-2', {
      'email': 'a@b.co',
      'username': 'abc',
      'friendCode': 'XYZ789',
    });

    expect(copy.experience, 0);
    expect(copy.coins, 0);
    expect(copy.diamonds, 0);
  });

  test('fromMap acepta números decimales de Firestore', () {
    final copy = UserProfile.fromMap('uid-3', {
      'email': 'a@b.co',
      'username': 'abc',
      'friendCode': 'XYZ789',
      'coins': 10.0,
    });

    expect(copy.coins, 10);
  });

  test('copyWith cambia solo lo pedido', () {
    final updated = profile.copyWith(coins: 99);

    expect(updated.coins, 99);
    expect(updated.experience, profile.experience);
    expect(updated.username, profile.username);
  });
}
