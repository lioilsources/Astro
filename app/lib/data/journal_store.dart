import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:astro_core/journal.dart';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../platform/blob_store.dart';

/// Where the encryption key lives (keychain/keystore in the app, a map in tests).
abstract interface class KeyVault {
  Future<String?> read(String name);
  Future<void> write(String name, String value);
}

class SecureKeyVault implements KeyVault {
  final FlutterSecureStorage _s;
  const SecureKeyVault([this._s = const FlutterSecureStorage()]);
  @override
  Future<String?> read(String name) => _s.read(key: name);
  @override
  Future<void> write(String name, String value) => _s.write(key: name, value: value);
}

/// One AES-GCM encrypted JSON document per file (local storage on the web), key kept in a [KeyVault].
/// Shared by the journal and later append-only logs (horary questions, R8).
class EncryptedJsonFiles {
  final String keyName;
  final KeyVault _vault;
  final BlobStore _blobs;
  final _algo = AesGcm.with256bits();
  Future<SecretKey>? _key;

  EncryptedJsonFiles(this.keyName, {KeyVault? vault, Future<Directory> Function()? dir})
      : _vault = vault ?? const SecureKeyVault(),
        _blobs = BlobStore.platform(dir);

  // Cached so two concurrent first uses never create two different keys.
  Future<SecretKey> _secret() => _key ??= () async {
        final stored = await _vault.read(keyName);
        if (stored != null) return SecretKey(base64Decode(stored));
        final r = Random.secure();
        final bytes = List<int>.generate(32, (_) => r.nextInt(256));
        await _vault.write(keyName, base64Encode(bytes));
        return SecretKey(bytes);
      }();

  Future<Object?> read(String relative) async {
    final bytes = await _blobs.read(relative);
    if (bytes == null) return null;
    final box = SecretBox.fromConcatenation(bytes, nonceLength: 12, macLength: 16);
    final clear = await _algo.decrypt(box, secretKey: await _secret());
    return jsonDecode(utf8.decode(clear));
  }

  Future<void> write(String relative, Object? json) async {
    final box = await _algo.encrypt(utf8.encode(jsonEncode(json)), secretKey: await _secret());
    await _blobs.write(relative, box.concatenation());
  }

  Future<void> delete(String relative) => _blobs.delete(relative);
}

/// Prediction journals, one encrypted file per profile (plan 10.3). Nothing leaves the device.
class JournalStore {
  final EncryptedJsonFiles files;
  JournalStore({KeyVault? vault, Future<Directory> Function()? dir})
    : files = EncryptedJsonFiles('astro_journal_key_v1', vault: vault, dir: dir);

  static String pathOf(String profileId) =>
      'journal/${base64Url.encode(utf8.encode(profileId)).replaceAll('=', '')}.bin';

  /// Throws [JournalSchemaError] for a file written by a newer app; the caller must not save over it.
  Future<Journal> load(String profileId) async {
    final json = await files.read(pathOf(profileId));
    if (json == null) return Journal();
    return Journal.fromJson((json as Map).cast<String, Object?>());
  }

  Future<void> save(String profileId, Journal j) => files.write(pathOf(profileId), j.toJson());

  Future<void> delete(String profileId) => files.delete(pathOf(profileId));
}
