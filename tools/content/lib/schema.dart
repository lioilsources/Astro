import 'dart:convert';
import 'dart:io';

import 'package:astro_core/content.dart';
export 'package:astro_core/content.dart';

List<Trait> loadTraits(Directory contentDir) {
  final f = File('${contentDir.path}/traits.json');
  if (!f.existsSync()) return const [];
  return parseTraits(jsonDecode(f.readAsStringSync()) as List);
}

/// Loads every `<family>.json` (a JSON array of entries) in [dir].
Map<String, ContentEntry> loadEntries(Directory dir) {
  final out = <String, ContentEntry>{};
  for (final family in allKeysByFamily().keys) {
    final f = File('${dir.path}/$family.json');
    if (!f.existsSync()) continue;
    for (final e in (jsonDecode(f.readAsStringSync()) as List).cast<Map>()) {
      final entry = ContentEntry.fromJson(e.cast<String, Object?>());
      out[entry.key] = entry;
    }
  }
  return out;
}

/// Writes entries of one family sorted by the canonical key order.
void writeFamily(Directory dir, String family, Iterable<ContentEntry> entries) {
  final order = {for (final (i, k) in allKeysByFamily()[family]!.indexed) k: i};
  final list = entries.toList()..sort((a, b) => (order[a.key] ?? 1 << 30).compareTo(order[b.key] ?? 1 << 30));
  const enc = JsonEncoder.withIndent(' ');
  File('${dir.path}/$family.json').writeAsStringSync('${enc.convert([for (final e in list) e.toJson()])}\n');
}

int wordCount(String s) => s.trim().isEmpty ? 0 : s.trim().split(RegExp(r'\s+')).length;
