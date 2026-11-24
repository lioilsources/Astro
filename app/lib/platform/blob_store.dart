import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Where the encrypted data files live: files in the app support directory on phones, base64 strings
/// in the browser's local storage on the web (no file system there). The bytes are already encrypted
/// by the caller; the key stays in flutter_secure_storage on both.
abstract interface class BlobStore {
  Future<List<int>?> read(String name);
  Future<void> write(String name, List<int> bytes);
  Future<void> delete(String name);

  /// Files under [dir] on phones (as before), local storage on the web.
  factory BlobStore.platform([Future<Directory> Function()? dir]) =>
      kIsWeb && dir == null ? PrefsBlobStore() : FileBlobStore(dir ?? getApplicationSupportDirectory);
}

class FileBlobStore implements BlobStore {
  final Future<Directory> Function() _dir;
  FileBlobStore(this._dir);

  Future<File> _file(String name) async => File('${(await _dir()).path}/$name');

  @override
  Future<List<int>?> read(String name) async {
    final f = await _file(name);
    return f.existsSync() ? f.readAsBytes() : null;
  }

  @override
  Future<void> write(String name, List<int> bytes) async {
    final f = await _file(name);
    await f.parent.create(recursive: true);
    final tmp = File('${f.path}.tmp');
    await tmp.writeAsBytes(bytes, flush: true);
    await tmp.rename(f.path);
  }

  @override
  Future<void> delete(String name) async {
    final f = await _file(name);
    if (f.existsSync()) await f.delete();
  }
}

class PrefsBlobStore implements BlobStore {
  static const _prefix = 'astro_blob:';

  @override
  Future<List<int>?> read(String name) async {
    final s = (await SharedPreferences.getInstance()).getString('$_prefix$name');
    return s == null ? null : base64Decode(s);
  }

  @override
  Future<void> write(String name, List<int> bytes) async =>
      (await SharedPreferences.getInstance()).setString('$_prefix$name', base64Encode(bytes));

  @override
  Future<void> delete(String name) async => (await SharedPreferences.getInstance()).remove('$_prefix$name');
}
