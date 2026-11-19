import 'dart:convert';
import 'dart:io';

import 'keys.dart';

const hardTopics = ['death', 'illness', 'mental_crisis', 'addiction', 'violence', 'loss', 'ruin'];
const themeIds = ['character', 'relationships', 'family', 'work', 'money', 'health', 'growth'];

/// Families whose texts are fragments for composing (no shadow layer required).
const shadowExempt = {'glossary', 'house_area', 'transit_modifier'};

class HardPassage {
  final List<String> topics;
  final String text;
  const HardPassage(this.topics, this.text);
  Map<String, Object?> toJson() => {'topics': topics, 'text': text};
}

class ContentEntry {
  final String key;
  final String title;
  final List<String> keywords;
  final List<String> themes;
  final String text;
  final String shadow;
  final List<HardPassage> hard;
  final List<String> traitsText;
  final List<String> traitsShadow;
  final Map<String, Object?> meta;

  const ContentEntry({
    required this.key,
    required this.title,
    this.keywords = const [],
    this.themes = const [],
    required this.text,
    this.shadow = '',
    this.hard = const [],
    this.traitsText = const [],
    this.traitsShadow = const [],
    this.meta = const {},
  });

  factory ContentEntry.fromJson(Map<String, Object?> j) {
    List<String> strs(Object? v) => (v as List? ?? const []).cast<String>();
    final traits = (j['traits'] as Map?)?.cast<String, Object?>() ?? const {};
    return ContentEntry(
      key: j['key'] as String,
      title: j['title'] as String? ?? '',
      keywords: strs(j['keywords']),
      themes: strs(j['themes']),
      text: j['text'] as String? ?? '',
      shadow: j['shadow'] as String? ?? '',
      hard: [
        for (final h in (j['hard'] as List? ?? const []).cast<Map>())
          HardPassage(strs(h['topics']), h['text'] as String? ?? ''),
      ],
      traitsText: strs(traits['text']),
      traitsShadow: strs(traits['shadow']),
      meta: (j['meta'] as Map?)?.cast<String, Object?>() ?? const {},
    );
  }

  Map<String, Object?> toJson() => {
        'key': key,
        'title': title,
        'keywords': keywords,
        'themes': themes,
        'text': text,
        if (shadow.isNotEmpty) 'shadow': shadow,
        if (hard.isNotEmpty) 'hard': [for (final h in hard) h.toJson()],
        'traits': {'text': traitsText, 'shadow': traitsShadow},
        if (meta.isNotEmpty) 'meta': meta,
      };
}

class Trait {
  final String id;
  final String name;
  final List<String> synonyms;
  final String? opposite;
  const Trait(this.id, this.name, this.synonyms, this.opposite);
}

List<Trait> loadTraits(Directory contentDir) {
  final f = File('${contentDir.path}/traits.json');
  if (!f.existsSync()) return const [];
  return [
    for (final t in (jsonDecode(f.readAsStringSync()) as List).cast<Map>())
      Trait(t['id'] as String, t['name'] as String, (t['synonyms'] as List? ?? const []).cast<String>(), t['opposite'] as String?),
  ];
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
