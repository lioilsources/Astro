const hardTopics = ['death', 'illness', 'mental_crisis', 'addiction', 'violence', 'loss', 'ruin'];
const themeIds = ['character', 'relationships', 'family', 'work', 'money', 'health', 'growth'];

/// Families whose texts are fragments for composing (no shadow layer required).
const shadowExempt = {'glossary', 'house_area', 'transit_modifier', 'star_target', 'journal'};

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

Map<String, ContentEntry> parseEntries(List<Object?> list) => {
      for (final e in list.cast<Map>())
        (e['key'] as String): ContentEntry.fromJson(e.cast<String, Object?>()),
    };

List<Trait> parseTraits(List<Object?> list) => [
      for (final t in list.cast<Map>())
        Trait(t['id'] as String, t['name'] as String, (t['synonyms'] as List? ?? const []).cast<String>(), t['opposite'] as String?),
    ];
