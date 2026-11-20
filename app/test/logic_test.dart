import 'dart:convert';
import 'dart:io';

import 'package:astro/data/content_repository.dart';
import 'package:astro/data/places.dart';
import 'package:astro/logic/filter.dart';
import 'package:astro/logic/queries.dart';
import 'package:astro/logic/reading.dart';
import 'package:astro_core/astro_core.dart';
import 'package:astro_core/content.dart';
import 'package:flutter_test/flutter_test.dart';

ContentRepository loadContent() {
  final dir = Directory('../content/cs');
  final entries = <String, ContentEntry>{};
  for (final f in allKeysByFamily().keys) {
    final file = File('${dir.path}/$f.json');
    if (file.existsSync()) entries.addAll(parseEntries(jsonDecode(file.readAsStringSync()) as List));
  }
  return ContentRepository(entries, parseTraits(jsonDecode(File('${dir.path}/traits.json').readAsStringSync()) as List));
}

final chart = Chart.compute(const BirthData(
  moment: LocalMoment(year: 2000, month: 1, day: 1, hour: 12, minute: 0, basis: TimeBasis.ut),
  lat: 50.0833,
  lon: 14.4167,
));

void main() {
  final content = loadContent();

  group('filter (plan 5.1)', () {
    final e = content['planet_in_sign/moon/scorpio']!;

    test('default shows everything', () {
      final f = ContentFilter.none.apply(e);
      expect(f.showShadow, isTrue);
      expect(f.visibleHard.length, e.hard.length);
      expect(f.hiddenCount, 0);
    });

    test('a hidden topic never shows and the count is right', () {
      final f = const ContentFilter(hiddenTopics: {'death'}).apply(e);
      expect(f.visibleHard.any((h) => h.topics.contains('death')), isFalse);
      expect(f.hiddenCount, e.hard.where((h) => h.topics.contains('death')).length);
    });

    test('hidden topics stay hidden across every text', () {
      final filter = ContentFilter(hiddenTopics: hardTopics.toSet(), hideShadow: true);
      for (final x in content.entries.values) {
        final f = filter.apply(x);
        expect(f.visibleHard, isEmpty, reason: x.key);
        expect(f.showShadow, isFalse);
        expect(f.hiddenCount, x.hard.length + (x.shadow.isEmpty ? 0 : 1));
      }
    });
  });

  test('reading puts shadow first for planets with a negative score', () {
    final items = readingItems(chart, content);
    for (final i in items.where((i) => i.factor.kind == FactorKind.planetInSign)) {
      expect(i.shadowFirst, (chart.states[i.factor.body]?.score ?? 0) < 0);
    }
    expect(bySections(items).first.id, 'signs');
  });

  test('star conjunctions form the last reading section, one item per star', () {
    // Sun at Regulus (~29°50′ Leo in 2000) around 22 August.
    final c = Chart.compute(const BirthData(
      moment: LocalMoment(year: 2000, month: 8, day: 22, hour: 12, minute: 0, basis: TimeBasis.ut),
      lat: 50.0833,
      lon: 14.4167,
    ));
    expect(c.starContacts.any((s) => s.star.id == 'regulus' && s.point == const ChartPoint.body(Body.sun)), isTrue);
    final sections = bySections(readingItems(c, content));
    expect(sections.last.id, 'stars');
    expect(sections.last.items.length, c.starContacts.map((s) => s.star.id).toSet().length);
  });

  group('trait query (plan 3.5 A)', () {
    test('finds a trait regardless of diacritics and synonyms', () {
      expect(findTrait('zarlivost', content.traits).trait?.id, 'jealousy');
      expect(findTrait('Nepořádek', content.traits).trait?.id, 'chaos');
    });

    test('unknown word suggests nearest traits', () {
      final r = findTrait('xyzzy', content.traits);
      expect(r.trait, isNull);
      expect(r.suggestions, isNotEmpty);
    });

    test('answer has both columns and is deterministic', () {
      final a = askTrait('vytrvalost', chart, content);
      final b = askTrait('vytrvalost', chart, content);
      expect(a.trait!.id, 'perseverance');
      expect([for (final m in a.supports) m.factor.key], [for (final m in b.supports) m.factor.key]);
      expect(a.supports.map((m) => m.factor.key), contains('aspect/sun/saturn/trine'));
    });
  });

  test('percentile', () {
    expect(percentileOf([1, 2, 3, 4], 3.5), 75);
    expect(percentileOf([], 1), 0);
  });

  group('places', () {
    test('fold strips diacritics', () {
      expect(fold('Břeclav Žďár Ústí'), 'breclav zdar usti');
    });

    test('search prefers Czech places and exact names', () async {
      final raw = File('assets/data/places.tsv').readAsStringSync();
      final idx = PlaceIndex([
        for (final line in raw.split('\n'))
          if (line.isNotEmpty && !line.startsWith('#')) Place.parse(line)
      ]);
      expect(idx.search('praha').first.zone, 'Europe/Prague');
      expect(idx.search('brno').first.country, 'CZ');
      expect(idx.search('new york').first.zone, 'America/New_York');
      expect(idx.search('prague').first.name, 'Praha');
      expect(idx.search('viden').first.zone, 'Europe/Vienna');
    });
  });
}
