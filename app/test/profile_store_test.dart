import 'dart:convert';
import 'dart:io';

import 'package:astro/data/profile.dart';
import 'package:astro/data/profile_store.dart';
import 'package:astro_core/astro_core.dart';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory dir;
  final key = List<int>.generate(32, (i) => i * 7 % 256);

  setUp(() {
    dir = Directory.systemTemp.createTempSync('astro_store_test');
    FlutterSecureStorage.setMockInitialValues({'astro_profiles_key_v1': base64Encode(key)});
  });
  tearDown(() => dir.deleteSync(recursive: true));

  test('profiles saved before R2 (no residence) still load, residence = birth place', () async {
    // Exactly the JSON shape written by the store before the residence field existed.
    final legacy = [
      {
        'id': 'a1',
        'name': 'Test',
        'birth': {
          'moment': {'year': 1990, 'month': 5, 'day': 1, 'hour': 8, 'minute': 30, 'calendar': 'gregorian', 'basis': 'zone', 'zone': 'Europe/Prague'},
          'lat': 49.2,
          'lon': 16.6,
          'place': 'Brno',
        },
        'houseSystem': null,
        'events': [],
      }
    ];
    final box = await AesGcm.with256bits().encrypt(utf8.encode(jsonEncode(legacy)), secretKey: SecretKey(key));
    File('${dir.path}/profiles.bin').writeAsBytesSync(box.concatenation());

    final store = ProfileStore(dir: () async => dir);
    final loaded = await store.load();
    expect(loaded.single.residence, isNull);
    expect(loaded.single.residencePlace, const GeoLocation(lat: 49.2, lon: 16.6, name: 'Brno', zone: 'Europe/Prague'));

    // Round trip with a residence.
    const praha = GeoLocation(lat: 50.0875, lon: 14.4214, name: 'Praha', zone: 'Europe/Prague');
    await store.save([loaded.single.copyWith(residence: praha)]);
    final again = await store.load();
    expect(again.single.residence, praha);
    expect(again.single.copyWith(clearResidence: true).residencePlace.name, 'Brno');
  });

  test('profile JSON without residence omits the field', () {
    const p = Profile(
      id: 'x',
      name: 'X',
      birth: BirthData(moment: LocalMoment(year: 2000, month: 1, day: 1), lat: 50, lon: 14),
    );
    expect(p.toJson().containsKey('residence'), isFalse);
    expect(Profile.fromJson(p.toJson()).residence, isNull);
  });
}
