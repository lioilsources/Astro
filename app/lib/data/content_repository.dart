import 'dart:convert';

import 'package:astro_core/content.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Interpretation texts and the trait vocabulary, loaded from bundled assets.
class ContentRepository {
  final Map<String, ContentEntry> entries;
  final List<Trait> traits;
  const ContentRepository(this.entries, this.traits);

  static Future<ContentRepository> load(AssetBundle bundle) async {
    final entries = <String, ContentEntry>{};
    for (final family in allKeysByFamily().keys) {
      try {
        final raw = await bundle.loadString('assets/content/$family.json');
        entries.addAll(parseEntries(jsonDecode(raw) as List));
      } on FlutterError {
        // Family not written yet.
      }
    }
    var traits = const <Trait>[];
    try {
      traits = parseTraits(jsonDecode(await bundle.loadString('assets/content/traits.json')) as List);
    } on FlutterError {
      // no vocabulary yet
    }
    return ContentRepository(entries, traits);
  }

  ContentEntry? operator [](String key) => entries[key];
  Trait? trait(String id) => traits.where((t) => t.id == id).firstOrNull;
}
