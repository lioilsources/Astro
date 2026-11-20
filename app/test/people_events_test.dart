import 'dart:convert';
import 'dart:io';

import 'package:astro/logic/people_events.dart';
import 'package:astro/ui/people_screen.dart';
import 'package:astro/ui/person_screen.dart';
import 'package:astro_core/astro_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'widget_test.dart' show wrap;

/// Synthetic catalog record (fictional person, no real birth data).
Map<String, Object?> _record({String? time}) => {
      'id': 'test-person',
      'name': 'Testovací osobnost',
      'categories': ['history'],
      'living': false,
      'wikidata': 'Q1',
      'birth': {
        'date': '1950-03-04',
        'calendar': 'gregorian',
        'time': ?time,
        if (time != null) 'time_basis': 'zone',
        'place': 'Praha',
        'lat': 50.0875,
        'lon': 14.4214,
        'zone': 'Europe/Prague',
      },
      'reliability': time == null ? 'X' : 'A',
      'source': {'note': 'test', 'url': 'https://example.org'},
      'events': [
        {'date': '1975-06-18', 'label': 'sňatek: někdo', 'type': 'marriage', 'defining': false, 'source': 'Wikidata Q1 P26 Q2', 'url': 'https://www.wikidata.org/wiki/Q1#P26'},
        {
          'date': '1970-01-10',
          'label': 'premiéra prvního díla',
          'type': 'premiere',
          'defining': true,
          'source': 'Wikipedia: Test',
          'url': 'https://en.wikipedia.org/wiki/Test',
          'quote': 'The work premiered on 10 January 1970.',
        },
        {'date': '1985-02-01', 'label': 'úmrtí', 'type': 'death', 'defining': false, 'source': 'Wikidata Q1 P570', 'url': 'https://www.wikidata.org/wiki/Q1#P570'},
      ],
    };

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({'onboardingDone': true}));

  test('catalog events parse chronologically with the defining flag', () {
    final p = Person.fromJson(_record());
    expect(p.catalogEvents.map((e) => e.date), ['1970-01-10', '1975-06-18', '1985-02-01']);
    expect(p.definingEvents.single.label, 'premiéra prvního díla');
    expect(p.deathJd, isNotNull);
    // Old records without the flag: offices, awards and works count as defining.
    expect(CatalogEvent.fromJson({'date': '1990-01-01', 'label': 'x', 'type': 'office', 'source': 's'}).defining, isTrue);
    expect(CatalogEvent.fromJson({'date': '1990-01-01', 'label': 'x', 'source': 's'}).defining, isFalse);
  });

  test('event moment is local noon in the birth zone', () {
    final p = Person.fromJson(_record());
    final jd = p.definingEvents.single.noonJd(p.profile.birth);
    // 10 January 1970, 12:00 CET = 11:00 UT.
    expect(jd, closeTo(julianDay(1970, 1, 10, 11), 1e-6));
  });

  test('every committed defining event resolves to a moment in its life', () {
    final raw = (jsonDecode(File('assets/data/people.json').readAsStringSync()) as List).cast<Map>();
    for (final j in raw) {
      final p = Person.fromJson(j.cast<String, Object?>());
      for (final e in p.definingEvents) {
        expect(e.noonJd(p.profile.birth), greaterThan(resolveMoment(p.profile.birth.moment, p.profile.birth.lon).jdUt - 1), reason: '${p.id} ${e.date}');
      }
    }
  });

  testWidgets('person detail opens the transit view of an event', (t) async {
    t.view.physicalSize = const Size(1170, 2532);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    final p = Person.fromJson(_record());
    await t.pumpWidget(wrap(PersonScreen(p)));
    await t.pumpAndSettle();
    expect(find.text('Čím je osobnost známá'), findsOneWidget);
    expect(find.text('Další události ze života'), findsOneWidget);
    await t.tap(find.text('premiéra prvního díla'));
    await t.pumpAndSettle();
    expect(find.text('Tranzity v den události'), findsOneWidget);
    expect(find.textContaining('poledne'), findsOneWidget);
    expect(find.textContaining('bez domů'), findsOneWidget);
    for (var i = 0; i < 240 && find.text('Počítám…').evaluate().isNotEmpty; i++) {
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 500)));
      await t.pump();
    }
    expect(find.text('Jak neobvyklý byl ten den'), findsOneWidget);
    expect(find.textContaining('dnů života této osobnosti'), findsOneWidget);
    expect(find.textContaining('čtení zpětně'), findsOneWidget);
    expect(find.text('Aktivní tranzity k horoskopu narození'), findsOneWidget);
    // No houses without a birth time.
    expect(find.textContaining('. dům'), findsNothing);
  });

  test('computeEventDay: rank within the life, houses only with a birth time', () {
    final timed = Person.fromJson(_record(time: '10:00'));
    final chart = Chart.compute(timed.profile.birth);
    final e = timed.definingEvents.single;
    final d = computeEventDay(chart, e.noonJd(timed.profile.birth), timed.deathJd, julianDay(2026, 1, 1, 0));
    expect(d.rank.u, inInclusiveRange(0, 1));
    expect(d.lifeDays, greaterThan(365 * 34));
    expect(d.positions.every((p) => p.house != null), isTrue);
    expect(d.transits.every((x) => x.orb >= 0), isTrue);
    expect(unusualness(d.rank.percentile), isIn(['calm', 'ordinary', 'tense', 'extreme']));
  });
}
