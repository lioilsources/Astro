import 'schema.dart';

class Finding {
  final String key;
  final String message;
  final bool error;
  const Finding(this.key, this.message, {this.error = false});
  @override
  String toString() => '${error ? 'ERROR' : 'warn '} $key: $message';
}

final _english = RegExp(r'\b(the|and|you|your|with|this|that|is|are|of)\b', caseSensitive: false);
final _diacritics = RegExp(r'[áčďéěíňóřšťúůýž]', caseSensitive: false);

/// Predicative adjectives or past tense tied to "ty" reveal grammatical gender (style rule).
final _gendered = RegExp(
  r'\b(jsi|bys|by sis|sis|ses)\s+(\w+(ý|á|ný|ná|lý|lá))\b|\b(byl|byla|mohl|mohla|chtěl|chtěla|musel|musela|udělal|udělala)\s+(jsi|bys)\b|\b(rád|ráda|sám|sama)\b',
  caseSensitive: false,
);

List<Finding> validate(Map<String, ContentEntry> entries, List<Trait> traits, {bool requireComplete = false}) {
  final out = <Finding>[];
  final known = {for (final f in allKeysByFamily().values) ...f};
  final traitIds = {for (final t in traits) t.id};

  for (final t in traits) {
    if (t.opposite != null && !traitIds.contains(t.opposite)) {
      out.add(Finding('traits/${t.id}', 'opposite ${t.opposite} is not in the vocabulary', error: true));
    }
  }

  for (final e in entries.values) {
    void err(String m) => out.add(Finding(e.key, m, error: true));
    void warn(String m) => out.add(Finding(e.key, m));
    final family = familyOf(e.key);
    if (!known.contains(e.key)) err('unknown key');
    if (e.title.trim().isEmpty) err('empty title');
    if (e.text.trim().isEmpty) err('empty text');
    if (!shadowExempt.contains(family) && e.shadow.trim().isEmpty) err('empty shadow');
    for (final th in e.themes) {
      if (!themeIds.contains(th)) err('unknown theme $th');
    }
    for (final h in e.hard) {
      if (h.topics.isEmpty) err('hard passage without topic');
      for (final t in h.topics) {
        if (!hardTopics.contains(t)) err('hard topic $t not in ${hardTopics.join(', ')}');
      }
      if (h.text.trim().isEmpty) err('empty hard passage');
    }
    if (traitIds.isNotEmpty) {
      for (final t in [...e.traitsText, ...e.traitsShadow]) {
        if (!traitIds.contains(t)) err('trait $t not in vocabulary');
      }
    }
    final all = [e.text, e.shadow, ...e.hard.map((h) => h.text)].join(' ');
    final eng = _english.allMatches(all).length;
    if (eng > 0) err('English words ($eng×): ${_english.allMatches(all).take(3).map((m) => m[0]).join(', ')}');
    if (wordCount(all) > 15 && !_diacritics.hasMatch(all)) err('no Czech diacritics');
    final g = _gendered.firstMatch(all);
    if (g != null) warn('gendered form "${g[0]}" (style: 2nd person without gender)');
    final range = lengthRange(e.key);
    final n = wordCount(e.text);
    if (n < range.min || n > range.max) warn('base layer $n words, expected ${range.min}–${range.max}');
    final ns = wordCount(e.shadow);
    final shadowMin = range.max <= 110 ? 20 : 30;
    if (!shadowExempt.contains(family) && (ns < shadowMin || ns > 130)) warn('shadow $ns words, expected $shadowMin–100');
    if (expectsHard(e.key) && e.hard.isEmpty) warn('tradition has hard topics here but `hard` is empty');
  }

  out.addAll(_similarity(entries));

  if (requireComplete) {
    for (final k in known) {
      if (!entries.containsKey(k)) out.add(Finding(k, 'missing text', error: true));
    }
  }
  return out;
}

/// Repeated 7-word phrases across different texts → monotony warning.
List<Finding> _similarity(Map<String, ContentEntry> entries) {
  final seen = <String, Set<String>>{};
  for (final e in entries.values) {
    final words = [e.text, e.shadow].join(' ').toLowerCase().replaceAll(RegExp(r'[^\p{L}\s]', unicode: true), ' ').split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    for (var i = 0; i + 7 <= words.length; i++) {
      seen.putIfAbsent(words.sublist(i, i + 7).join(' '), () => {}).add(e.key);
    }
  }
  final limit = entries.length < 50 ? 2 : 4;
  return [
    for (final MapEntry(:key, :value) in seen.entries)
      if (value.length > limit) Finding(value.first, 'phrase "$key" repeats in ${value.length} texts'),
  ];
}
