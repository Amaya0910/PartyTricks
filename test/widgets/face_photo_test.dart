import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:party_tricks/controllers/face_photo_controller.dart';
import 'package:party_tricks/models/face_photo.dart';
import 'package:party_tricks/models/social/public_profile.dart';
import 'package:party_tricks/models/user_profile.dart';
import 'package:party_tricks/screens/face_photo_screen.dart';
import 'package:party_tricks/services/auth/auth_providers.dart';
import 'package:party_tricks/services/character/character_providers.dart';
import 'package:party_tricks/services/character/character_service.dart';
import 'package:party_tricks/services/character/face_camera.dart';
import 'package:party_tricks/services/character/face_image_service.dart';
import 'package:party_tricks/widgets/character/animated_character.dart';
import 'package:party_tricks/widgets/character/face_photo_layer.dart';
import 'package:party_tricks/widgets/character/head_avatar.dart';
import 'package:party_tricks/widgets/character/head_shape.dart';
import 'package:party_tricks/widgets/face_camera_view.dart';
import 'package:party_tricks/widgets/face_photo_editor.dart';

/// Un JPEG de prueba: la mitad izquierda roja y la derecha azul.
Uint8List _jpeg({int width = 640, int height = 480}) {
  final image = img.Image(width: width, height: height);
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      image.setPixelRgb(
        x,
        y,
        x < width / 2 ? 220 : 20,
        30,
        x < width / 2 ? 20 : 220,
      );
    }
  }
  return Uint8List.fromList(img.encodeJpg(image, quality: 95));
}

FaceSourceImage _source({int width = 640, int height = 480}) =>
    FaceImageProcessor.prepare(_jpeg(width: width, height: height))!;

FacePhoto _photo([FaceCrop crop = const FaceCrop()]) =>
    FaceImageProcessor.render(_source(), crop)!;

/// Color en un punto de la foto final, de 0 a 1.
img.Pixel _pixel(FacePhoto photo, double x, double y) {
  final decoded = img.decodeJpg(photo.bytes)!;
  return decoded.getPixel(
    (x * (decoded.width - 1)).round(),
    (y * (decoded.height - 1)).round(),
  );
}

bool _isRed(img.Pixel pixel) => pixel.r > 150 && pixel.b < 100;
bool _isBlue(img.Pixel pixel) => pixel.b > 150 && pixel.r < 100;

class _FakeCharacterService implements CharacterService {
  _FakeCharacterService(this.onChange);

  final void Function(UserProfile Function(UserProfile)) onChange;

  @override
  Future<void> setFacePhoto({
    required String uid,
    required FacePhoto? photo,
  }) async => onChange(
    (p) => photo == null
        ? p.copyWith(clearFacePhoto: true)
        : p.copyWith(facePhoto: photo),
  );

  @override
  Future<void> setUseFacePhoto({
    required String uid,
    required bool use,
  }) async => onChange((p) => p.copyWith(useFacePhoto: use));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Hace las mismas cuentas de verdad, pero sin otro hilo.
class _FakeFaceImageService implements FaceImageService {
  FaceSourceImage? gallery;
  bool galleryAsked = false;

  @override
  Future<FaceSourceImage?> pickFromGallery() async {
    galleryAsked = true;
    return gallery;
  }

  @override
  Future<FaceSourceImage> prepare(Uint8List bytes) async =>
      FaceImageProcessor.prepare(bytes)!;

  @override
  Future<FacePhoto> render(FaceSourceImage source, FaceCrop crop) async =>
      FaceImageProcessor.render(source, crop)!;
}

class _FakeCamera implements FaceCamera {
  _FakeCamera({this.failure});

  final String? failure;
  bool opened = false;
  bool closed = false;
  int switches = 0;

  @override
  Future<void> open() async {
    if (failure != null) throw CharacterException(failure!);
    opened = true;
  }

  @override
  Widget preview() =>
      const ColoredBox(key: ValueKey('vista-camara'), color: Colors.green);

  @override
  double get aspectRatio => 3 / 4;

  @override
  bool get canSwitch => true;

  @override
  Future<void> switchCamera() async => switches++;

  @override
  Future<Uint8List> takePicture() async => _jpeg();

  @override
  Future<void> close() async => closed = true;
}

void main() {
  group('procesar la foto', () {
    test('endereza y reduce las fotos grandes para editarlas', () {
      final source = _source(width: 2000, height: 1000);
      expect(source.width, 1280);
      expect(source.height, 640);
    });

    test('un archivo que no es imagen no se acepta', () {
      expect(FaceImageProcessor.prepare(Uint8List.fromList([1, 2, 3])), isNull);
    });

    test('el resultado es cuadrado y cabe en el límite', () {
      final photo = _photo();
      final decoded = img.decodeJpg(photo.bytes)!;
      expect(decoded.width, FaceImageProcessor.side);
      expect(decoded.height, FaceImageProcessor.side);
      expect(photo.base64.length, lessThanOrEqualTo(FacePhoto.maxLength));
    });

    test('sin cambios, la foto se centra en la zona', () {
      final photo = _photo();
      expect(_isRed(_pixel(photo, 0.2, 0.5)), isTrue);
      expect(_isBlue(_pixel(photo, 0.8, 0.5)), isTrue);
    });

    test('mover la foto a la derecha deja ver más de su lado izquierdo', () {
      final photo = _photo(const FaceCrop(dx: 0.4));
      expect(_isRed(_pixel(photo, 0.8, 0.5)), isTrue);
    });

    test('el zoom acerca la foto hacia el centro', () {
      final photo = _photo(const FaceCrop(scale: 4, dx: 0.5));
      expect(_isRed(_pixel(photo, 0.9, 0.5)), isTrue);
    });

    test('voltear cambia de lado la foto', () {
      final photo = _photo(const FaceCrop(mirrored: true));
      expect(_isBlue(_pixel(photo, 0.2, 0.5)), isTrue);
      expect(_isRed(_pixel(photo, 0.8, 0.5)), isTrue);
    });

    test('girar media vuelta también la cambia de lado', () {
      final photo = _photo(const FaceCrop(rotation: 3.141592653589793));
      expect(_isBlue(_pixel(photo, 0.2, 0.5)), isTrue);
    });

    test('lo que queda sin foto se rellena de gris', () {
      final photo = _photo(const FaceCrop(dx: 2));
      final corner = _pixel(photo, 0.05, 0.5);
      expect(corner.r, greaterThan(200));
      expect(corner.b, greaterThan(200));
    });
  });

  test('el recorte no deja que la foto se salga de la zona', () {
    final crop = const FaceCrop(scale: 99, dx: 99, dy: -99).clamped(400, 300);
    expect(crop.scale, FaceCrop.maxScale);
    expect(crop.dx, closeTo(5 * 400 / 300 / 2, 0.001));
    expect(crop.dy, -2.5);
  });

  test('el contorno de la cabeza cabe en la zona y se adapta al tamaño', () {
    const target = Rect.fromLTWH(10, 20, 200, 200);
    final bounds = HeadShape.pathIn(target).getBounds();
    expect(target.inflate(1).contains(bounds.topLeft), isTrue);
    expect(target.inflate(1).contains(bounds.bottomRight), isTrue);
    expect(bounds.width, greaterThan(180));
    expect(HeadShape.pathIn(target).contains(target.center), isTrue);
    expect(HeadShape.pathIn(target).contains(target.topLeft), isFalse);
  });

  test('la foto se guarda como texto y se vuelve a leer igual', () {
    final photo = _photo();
    final read = FacePhoto.fromStored(photo.base64)!;
    expect(read, photo);
    expect(read.bytes, photo.bytes);
    expect(FacePhoto.fromStored(null), isNull);
    expect(FacePhoto.fromStored('no es base64 !!!'), isNull);
    expect(FacePhoto.fromStored('A' * (FacePhoto.maxLength + 4)), isNull);
  });

  test('el perfil guarda la foto y si la usa', () {
    final photo = _photo();
    final profile = UserProfile(
      uid: 'u',
      email: 'a@b.co',
      username: 'abc',
      friendCode: 'XYZ789',
      facePhoto: photo,
    );
    expect(profile.shownFacePhoto, photo);

    final read = UserProfile.fromMap('u', profile.toMap());
    expect(read.facePhoto, photo);
    expect(read.useFacePhoto, isTrue);

    final off = profile.copyWith(useFacePhoto: false);
    expect(off.shownFacePhoto, isNull);
    expect(UserProfile.fromMap('u', off.toMap()).useFacePhoto, isFalse);

    final cleared = profile.copyWith(clearFacePhoto: true);
    expect(cleared.facePhoto, isNull);
    expect(cleared.toMap().containsKey('facePhoto'), isFalse);
  });

  test('el perfil público lleva la foto', () {
    final photo = _photo();
    final read = PublicProfile.fromMap(
      'u',
      PublicProfile(uid: 'u', username: 'Ana', facePhoto: photo).toMap(),
    );
    expect(read.facePhoto, photo);
    expect(PublicProfile.fromMap('u', {'username': 'Ana'}).facePhoto, isNull);
  });

  testWidgets('con foto, el personaje y la foto de perfil la dibujan', (
    tester,
  ) async {
    final photo = _photo();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              SizedBox(
                height: 200,
                child: AnimatedCharacter(
                  skinTone: Colors.orange,
                  facePhoto: photo,
                ),
              ),
              HeadAvatar(facePhoto: photo),
            ],
          ),
        ),
      ),
    );
    expect(find.byType(FacePhotoLayer), findsNWidgets(2));
  });

  testWidgets('sin foto no se dibuja la capa de la foto', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: AnimatedCharacter(skinTone: Colors.orange)),
      ),
    );
    expect(find.byType(FacePhotoLayer), findsNothing);
  });

  group('pantalla de la foto', () {
    late ProviderContainer container;
    late _FakeFaceImageService images;
    late _FakeCamera camera;
    late UserProfile current;

    Future<void> open(
      WidgetTester tester, {
      FacePhoto? saved,
      String? cameraFailure,
    }) async {
      tester.view.physicalSize = const Size(420, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      current = UserProfile(
        uid: 'u',
        email: 'a@b.co',
        username: 'abc',
        friendCode: 'XYZ789',
        facePhoto: saved,
      );
      late void Function(UserProfile) emit;
      final stream = Stream<UserProfile>.multi((controller) {
        controller.add(current);
        emit = controller.add;
      });
      images = _FakeFaceImageService();
      camera = _FakeCamera(failure: cameraFailure);
      container = ProviderContainer(
        overrides: [
          userProfileProvider.overrideWith((ref) => stream),
          characterServiceProvider.overrideWithValue(
            _FakeCharacterService((change) {
              current = change(current);
              emit(current);
            }),
          ),
          faceImageServiceProvider.overrideWithValue(images),
          faceCameraProvider.overrideWithValue(camera),
        ],
      );
      addTearDown(container.dispose);
      // En la app, el perfil ya está cargado al abrir la pantalla.
      container.listen(userProfileProvider, (_, _) {});
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: TextButton(
                    onPressed: () =>
                        Navigator.of(context).push(FacePhotoScreen.route()),
                    child: const Text('Abrir'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.text('Abrir'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
    }

    Future<void> settle(WidgetTester tester) async {
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    testWidgets('sin foto guardada abre la cámara con la silueta', (
      tester,
    ) async {
      await open(tester);
      expect(camera.opened, isTrue);
      expect(find.byKey(const ValueKey('vista-camara')), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (w) => w is CustomPaint && w.painter is HeadGuidePainter,
        ),
        findsOneWidget,
      );
    });

    testWidgets('tomar la foto abre el editor, sin guardarla todavía', (
      tester,
    ) async {
      await open(tester);
      await tester.tap(find.bySemanticsLabel('Tomar foto'));
      await settle(tester);

      expect(find.byType(FacePhotoEditor), findsOneWidget);
      expect(find.text('Guardar'), findsOneWidget);
      expect(container.read(savedFacePhotoProvider), isNull);
      // El personaje de abajo ya muestra el resultado.
      expect(find.byType(FacePhotoLayer), findsOneWidget);
      expect(camera.closed, isTrue);
    });

    testWidgets('guardar deja la foto puesta y muestra el resultado', (
      tester,
    ) async {
      await open(tester);
      await tester.tap(find.bySemanticsLabel('Tomar foto'));
      await settle(tester);

      await tester.tap(find.text('Guardar'));
      await settle(tester);
      expect(container.read(savedFacePhotoProvider), isNotNull);
      expect(container.read(facePhotoProvider), isNotNull);
      expect(find.text('Quitar mi foto'), findsOneWidget);
    });

    testWidgets('Repetir vuelve a la cámara', (tester) async {
      await open(tester);
      await tester.tap(find.bySemanticsLabel('Tomar foto'));
      await settle(tester);

      await tester.tap(find.text('Repetir'));
      await settle(tester);
      expect(find.byType(FaceCameraView), findsOneWidget);
      expect(container.read(savedFacePhotoProvider), isNull);
    });

    testWidgets('arrastrar mueve la foto y cambia el resultado', (
      tester,
    ) async {
      await open(tester);
      await tester.tap(find.bySemanticsLabel('Tomar foto'));
      await settle(tester);
      final before = tester
          .widget<FacePhotoLayer>(find.byType(FacePhotoLayer))
          .photo;

      await tester.drag(find.byType(CustomPaint).first, const Offset(120, 0));
      await settle(tester);
      final after = tester
          .widget<FacePhotoLayer>(find.byType(FacePhotoLayer))
          .photo;
      expect(after, isNot(before));
    });

    testWidgets('elegir de la galería abre el editor', (tester) async {
      await open(tester);
      images.gallery = _source();
      await tester.tap(find.byTooltip('Galería'));
      await settle(tester);
      expect(images.galleryAsked, isTrue);
      expect(find.byType(FacePhotoEditor), findsOneWidget);
    });

    testWidgets('si no hay cámara lo dice y deja usar la galería', (
      tester,
    ) async {
      await open(tester, cameraFailure: 'Sin permiso para usar la cámara.');
      expect(find.text('Sin permiso para usar la cámara.'), findsOneWidget);
      images.gallery = _source();
      await tester.tap(find.byTooltip('Galería'));
      await settle(tester);
      expect(find.byType(FacePhotoEditor), findsOneWidget);
    });

    testWidgets('con foto guardada se puede ajustar, apagar y quitar', (
      tester,
    ) async {
      await open(tester, saved: _photo());
      expect(find.text('Ajustar'), findsOneWidget);

      await tester.tap(find.byType(Switch));
      await settle(tester);
      expect(container.read(useFacePhotoProvider), isFalse);
      expect(container.read(facePhotoProvider), isNull);

      await tester.tap(find.text('Ajustar'));
      await settle(tester);
      expect(find.byType(FacePhotoEditor), findsOneWidget);

      await tester.tap(find.text('Repetir'));
      await settle(tester);
      await tester.tap(find.byTooltip('Volver'));
      await settle(tester);

      await tester.tap(find.text('Quitar mi foto'));
      await settle(tester);
      expect(container.read(savedFacePhotoProvider), isNull);
    });
  });
}
