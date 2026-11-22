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

/// "sám o sobě" about a thing and "sebe sama" are not about the reader's gender.
final _neutralSelf = RegExp(r'\b(sám|sama|samo) (o sobě|od sebe)|\bsebe sama', caseSensitive: false);

/// Romance and sexuality: in synastry texts they belong only to the `partner`
/// layer, because the base layers are shown for parent and child too (plan 10.4).
final romantic = RegExp(
  // "sextil" is an aspect; "svádí k…" (tempts/leads to) is neutral, so seduction is not listed.
  r'\b((?!sextil)sex\w*|erot\w*|milen\w*|milostn\w*|intimn\w*|zamilov\w*|flirt\w*|polib\w*|políb\w*|líba\w*|postel\w*)',
  caseSensitive: false,
  unicode: true,
);

/// A verdict on the relationship does not belong in advice (plan R9 5.2).
/// "odejděte na chvíli" is fine, so leaving as such is not listed.
final _verdict = RegExp(r'\b(rozej\w*|rozchod\w*|rozv[eé]\w*|rozvod\w*|opus[tť]\w*)', caseSensitive: false, unicode: true);

/// Third person with gender in `pair_need` (plan R9 5.3).
final _genderedPronoun = RegExp(r'(?<![\p{L}])(on|ona|jeho|její)(?![\p{L}])', caseSensitive: false, unicode: true);

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
    if (!isShadowExempt(e.key) && e.shadow.trim().isEmpty) err('empty shadow');
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
    if (e.partner.trim().isNotEmpty && !allowsPartner(e.key)) {
      err('`partner` layer only belongs to ${partnerFamilies.join(', ')} and Venus/Mars of pair_need, pair_elements');
    }
    final advice = e.advice.trim();
    if (advice.isNotEmpty && !adviceFamilies.contains(family)) err('`advice` layer only belongs to ${adviceFamilies.join(', ')}');
    if (advice.isEmpty && adviceRequiredFamilies.contains(family)) err('empty advice');
    if (advice.isNotEmpty) {
      final v = _verdict.firstMatch(advice);
      if (v != null) err('verdict "${v[0]}" in advice (plan R9 5.2: no verdict on the relationship)');
      final na = wordCount(advice);
      final (lo, hi) = family == 'pair_period' ? (40, 80) : (30, 70);
      if (na < lo - 5 || na > hi + 15) warn('advice $na words, expected $lo–$hi');
    }
    if (family == 'pair_need') {
      final m = _genderedPronoun.firstMatch([e.text, e.shadow, advice].join(' '));
      if (m != null) warn('pronoun "${m[0]}" in pair_need (style: "ten druhý", no gender)');
    }
    if (relationshipFamilies.contains(family)) {
      final base = [e.title, e.text, e.shadow, advice, ...e.keywords, ...e.hard.map((h) => h.text)].join(' ');
      final m = romantic.firstMatch(base);
      if (m != null) err('romantic word "${m[0]}" outside `partner` (base layers are shown for parent and child too)');
      final np = wordCount(e.partner);
      if (np > 0 && (np < 20 || np > 90)) warn('partner $np words, expected 20–80');
    }
    final all = [e.text, e.shadow, ...e.hard.map((h) => h.text), e.partner, e.advice].join(' ');
    final eng = _english.allMatches(all).length;
    if (eng > 0) err('English words ($eng×): ${_english.allMatches(all).take(3).map((m) => m[0]).join(', ')}');
    if (wordCount(all) > 15 && !_diacritics.hasMatch(all)) err('no Czech diacritics');
    final g = _gendered.firstMatch(all.replaceAll(_neutralSelf, ''));
    if (g != null) warn('gendered form "${g[0]}" (style: 2nd person without gender)');
    final range = lengthRange(e.key);
    final n = wordCount(e.text);
    if (n < range.min || n > range.max) warn('base layer $n words, expected ${range.min}–${range.max}');
    if (family == 'star') {
      // Plan 10.6: 150–250 words including layers; the hard intro is mandatory.
      final total = wordCount(all);
      if (total < 150 || total > 250) warn('star text $total words with layers, expected 150–250');
      for (final h in e.hard) {
        if (!h.text.toLowerCase().contains('tradice')) warn('hard passage without the "tradice tu mluví o…" intro');
      }
    }
    final ns = wordCount(e.shadow);
    final shadowMin = range.max <= 110 ? 20 : 30;
    if (!isShadowExempt(e.key) && (ns < shadowMin || ns > 130)) warn('shadow $ns words, expected $shadowMin–100');
    if (expectsHard(e.key) && e.hard.isEmpty) warn('tradition has hard topics here but `hard` is empty');
  }

  out.addAll(_similarity(entries));

  if (requireComplete) {
    for (final k in known) {
      if (!entries.containsKey(k)) out.add(Finding(k, 'missing text', error: true));
    }
    for (final e in entries.values) {
      if (adviceFamilies.contains(familyOf(e.key)) && e.advice.trim().isEmpty) out.add(Finding(e.key, 'missing advice', error: true));
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
