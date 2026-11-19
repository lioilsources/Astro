import 'dart:math' as math;

import 'package:astro_core/astro_core.dart';
import 'package:astro_core/content.dart';

import '../data/content_repository.dart';
import '../data/places.dart' show fold;

class TraitMatch {
  final Factor factor;
  final ContentEntry entry;

  /// Which layer carries the tag: `text` or `shadow`.
  final String layer;
  const TraitMatch(this.factor, this.entry, this.layer);
}

class TraitAnswer {
  final Trait? trait;
  final List<TraitMatch> supports;
  final List<TraitMatch> against;
  final List<Trait> suggestions;
  const TraitAnswer(this.trait, this.supports, this.against, this.suggestions);
}

int _levenshtein(String a, String b) {
  if (a == b) return 0;
  var prev = List<int>.generate(b.length + 1, (i) => i);
  for (var i = 1; i <= a.length; i++) {
    final cur = List<int>.filled(b.length + 1, 0)..[0] = i;
    for (var j = 1; j <= b.length; j++) {
      cur[j] = math.min(math.min(cur[j - 1] + 1, prev[j] + 1), prev[j - 1] + (a[i - 1] == b[j - 1] ? 0 : 1));
    }
    prev = cur;
  }
  return prev[b.length];
}

/// Finds a trait by name or synonym regardless of diacritics; suggests the nearest otherwise.
({Trait? trait, List<Trait> suggestions}) findTrait(String query, List<Trait> traits) {
  final q = fold(query.trim());
  if (q.isEmpty) return (trait: null, suggestions: const []);
  List<String> names(Trait t) => [t.name, ...t.synonyms].map(fold).toList();
  for (final t in traits) {
    if (names(t).contains(q)) return (trait: t, suggestions: const []);
  }
  // Czech inflection: compare stems (first 5 letters) before giving up.
  final stem = q.length > 5 ? q.substring(0, 5) : q;
  for (final t in traits) {
    if (names(t).any((n) => n.startsWith(stem) || n.split(' ').any((w) => w.startsWith(stem)))) {
      return (trait: t, suggestions: const []);
    }
  }
  final scored = [
    for (final t in traits) (t, names(t).map((n) => _levenshtein(q, n)).reduce(math.min)),
  ]..sort((a, b) => a.$2.compareTo(b.$2));
  return (trait: null, suggestions: scored.take(5).map((e) => e.$1).toList());
}

/// Query A (plan 3.5): factors that support the trait and factors that speak against it.
TraitAnswer askTrait(String query, Chart chart, ContentRepository content) {
  final found = findTrait(query, content.traits);
  final t = found.trait;
  if (t == null) return TraitAnswer(null, const [], const [], found.suggestions);
  final supports = <TraitMatch>[], against = <TraitMatch>[];
  for (final f in factorsOf(chart)) {
    final e = content[f.key];
    if (e == null) continue;
    void check(List<String> tags, String layer) {
      if (tags.contains(t.id)) supports.add(TraitMatch(f, e, layer));
      if (t.opposite != null && tags.contains(t.opposite)) against.add(TraitMatch(f, e, layer));
    }

    check(e.traitsText, 'text');
    check(e.traitsShadow, 'shadow');
  }
  int byWeight(TraitMatch a, TraitMatch b) {
    final w = b.factor.weight.compareTo(a.factor.weight);
    return w != 0 ? w : a.factor.key.compareTo(b.factor.key);
  }

  supports.sort(byWeight);
  against.sort(byWeight);
  return TraitAnswer(t, supports, against, const []);
}

/// Sidereal periods in years — how often a transit configuration comes back.
const orbitalYears = {
  Body.sun: 1.0, Body.moon: 0.0748, Body.mercury: 1.0, Body.venus: 1.0, Body.mars: 1.88,
  Body.jupiter: 11.86, Body.saturn: 29.46, Body.uranus: 84.0, Body.neptune: 164.8, Body.pluto: 248.0,
};

/// Years between repetitions of the same transit (two sides for square, trine, sextile).
double recurrenceYears(TransitEvent e) {
  final p = orbitalYears[e.transiting]!;
  return (e.type == AspectType.conjunction || e.type == AspectType.opposition) ? p : p / 2;
}

bool isTenseTransit(TransitEvent e) {
  if (e.type.quality == AspectQuality.tense) return true;
  if (e.type.quality == AspectQuality.harmonious) return false;
  return const {Body.mars, Body.saturn, Body.uranus, Body.neptune, Body.pluto}.contains(e.transiting);
}

/// Percentile (0–100) of [value] within [series]: share of days with lower tension.
int percentileOf(List<double> series, double value) {
  if (series.isEmpty) return 0;
  final below = series.where((v) => v < value).length;
  return (100 * below / series.length).floor();
}
