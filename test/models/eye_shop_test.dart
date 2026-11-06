import 'package:flutter_test/flutter_test.dart';
import 'package:party_tricks/models/eye_style.dart';
import 'package:party_tricks/models/user_profile.dart';

void main() {
  const profile = UserProfile(
    uid: 'u',
    email: 'a@b.co',
    username: 'abc',
    friendCode: 'XYZ789',
    ownedEyes: {3, 9},
  );

  test('los ojos 2, 5 y 7 son gratis y el de inicio es gratis', () {
    final free = [
      for (final style in EyeStyle.values)
        if (style.isFree) style.number,
    ];
    expect(free, [2, 5, 7]);
    expect(EyeStyle.defaultStyle.isFree, isTrue);
  });

  test('cada ojo de la Tienda tiene nombre, descripción y precio', () {
    for (final style in EyeStyle.values.where((s) => !s.isFree)) {
      expect(style.title, isNotEmpty);
      expect(style.description, isNotEmpty);
      expect(style.price, greaterThan(0));
    }
  });

  test('tiene los gratis y los comprados', () {
    expect(profile.ownsEyes(EyeStyle.ojo7), isTrue);
    expect(profile.ownsEyes(EyeStyle.ojo3), isTrue);
    expect(profile.ownsEyes(EyeStyle.ojo9), isTrue);
    expect(profile.ownsEyes(EyeStyle.ojo1), isFalse);
  });

  test('los ojos comprados se guardan y se leen de Firestore', () {
    final map = profile.toMap();
    expect(map['ownedEyes'], [3, 9]);
    expect(UserProfile.fromMap('u', map).ownedEyes, {3, 9});
  });

  test('sin el campo, no tiene ojos comprados', () {
    final read = UserProfile.fromMap('u', {'username': 'abc'});
    expect(read.ownedEyes, isEmpty);
    expect(read.ownsEyes(EyeStyle.ojo2), isTrue);
  });
}
