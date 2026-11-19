import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';

import 'profile.dart';

/// Profiles live in one AES-GCM encrypted file; the key is kept in the
/// platform keychain/keystore. Nothing leaves the device.
class ProfileStore {
  static const _keyName = 'astro_profiles_key_v1';
  final FlutterSecureStorage _secure;
  final Future<Directory> Function() _dir;
  final _algo = AesGcm.with256bits();

  ProfileStore({FlutterSecureStorage? secure, Future<Directory> Function()? dir})
      : _secure = secure ?? const FlutterSecureStorage(),
        _dir = dir ?? getApplicationSupportDirectory;

  Future<File> _file() async => File('${(await _dir()).path}/profiles.bin');

  Future<SecretKey> _key() async {
    final stored = await _secure.read(key: _keyName);
    if (stored != null) return SecretKey(base64Decode(stored));
    final r = Random.secure();
    final bytes = List<int>.generate(32, (_) => r.nextInt(256));
    await _secure.write(key: _keyName, value: base64Encode(bytes));
    return SecretKey(bytes);
  }

  Future<List<Profile>> load() async {
    final f = await _file();
    if (!f.existsSync()) return [];
    final box = SecretBox.fromConcatenation(await f.readAsBytes(), nonceLength: 12, macLength: 16);
    final clear = await _algo.decrypt(box, secretKey: await _key());
    final list = jsonDecode(utf8.decode(clear)) as List;
    return [for (final p in list) Profile.fromJson((p as Map).cast<String, Object?>())];
  }

  Future<void> save(List<Profile> profiles) async {
    final clear = utf8.encode(jsonEncode([for (final p in profiles) p.toJson()]));
    final box = await _algo.encrypt(clear, secretKey: await _key());
    final f = await _file();
    await f.parent.create(recursive: true);
    final tmp = File('${f.path}.tmp');
    await tmp.writeAsBytes(box.concatenation(), flush: true);
    await tmp.rename(f.path);
  }
}
