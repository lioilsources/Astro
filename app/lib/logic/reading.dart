import 'package:astro_core/astro_core.dart';
import 'package:astro_core/content.dart';

import '../data/content_repository.dart';

/// One item of the reading: a chart factor with its text (or null when missing).
class ReadingItem {
  final Factor factor;
  final ContentEntry? entry;

  /// Negative planet score → shadow goes before the base text (plan 4.1).
  final bool shadowFirst;
  const ReadingItem(this.factor, this.entry, this.shadowFirst);
}

class ReadingSection {
  final String id;
  final List<ReadingItem> items;
  const ReadingSection(this.id, this.items);
}

List<ReadingItem> readingItems(Chart chart, ContentRepository content) => [
      for (final f in factorsOf(chart))
        ReadingItem(f, content[f.key], f.body != null && (chart.states[f.body]?.score ?? 0) < 0),
    ];

/// Sections in the order of the old Astromat reading: signs, houses, aspects, cusps, emphasis.
List<ReadingSection> bySections(List<ReadingItem> items) {
  const order = {
    FactorKind.planetInSign: 'signs',
    FactorKind.planetInHouse: 'houses',
    FactorKind.aspect: 'aspects',
    FactorKind.aspectPoint: 'aspects',
    FactorKind.signOnCusp: 'cusps',
    FactorKind.emphasis: 'emphasis',
    FactorKind.moonPhase: 'emphasis',
  };
  final out = <String, List<ReadingItem>>{};
  for (final i in items) {
    out.putIfAbsent(order[i.factor.kind]!, () => []).add(i);
  }
  return [for (final id in ['signs', 'houses', 'aspects', 'cusps', 'emphasis']) if (out[id] != null) ReadingSection(id, out[id]!)];
}

/// Grouped by themes of the texts; items without a text are left out.
List<ReadingSection> byThemes(List<ReadingItem> items) {
  final out = <String, List<ReadingItem>>{};
  for (final i in items) {
    final e = i.entry;
    if (e == null) continue;
    for (final t in e.themes.isEmpty ? const ['other'] : e.themes) {
      out.putIfAbsent(t, () => []).add(i);
    }
  }
  for (final l in out.values) {
    l.sort((a, b) => b.factor.weight.compareTo(a.factor.weight));
  }
  return [
    for (final t in [...themeIds, 'other'])
      if (out[t] != null) ReadingSection(t, out[t]!)
  ];
}
