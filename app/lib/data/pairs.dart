import 'dart:io';

import 'package:astro_core/astro_core.dart';

import 'journal_store.dart';

/// A saved pair of profiles for the relationship guide (plan R9 6.1).
class Pair {
  final String id;
  final String firstId;
  final String secondId;
  final Relationship relationship;
  const Pair({required this.id, required this.firstId, required this.secondId, required this.relationship});

  bool involves(String profileId) => firstId == profileId || secondId == profileId;

  Map<String, Object?> toJson() => {'id': id, 'first': firstId, 'second': secondId, 'relationship': relationship.name};

  factory Pair.fromJson(Map<String, Object?> j) => Pair(
        id: j['id'] as String,
        firstId: j['first'] as String,
        secondId: j['second'] as String,
        relationship: Relationship.values.asNameMap()[j['relationship']] ?? Relationship.partner,
      );
}

/// Saved pairs in one encrypted file, key in the keychain (like the journal).
class PairStore {
  final EncryptedJsonFiles files;
  PairStore({KeyVault? vault, Future<Directory> Function()? dir})
      : files = EncryptedJsonFiles('astro_pairs_key_v1', vault: vault, dir: dir);

  static const path = 'pairs.bin';

  Future<List<Pair>> load() async {
    final json = await files.read(path);
    if (json == null) return [];
    return [for (final p in json as List) Pair.fromJson((p as Map).cast<String, Object?>())];
  }

  Future<void> save(List<Pair> pairs) => files.write(path, [for (final p in pairs) p.toJson()]);
}
