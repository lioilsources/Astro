import 'package:astro/export/ics_export.dart';
import 'package:astro/logic/election.dart';
import 'package:astro/ui/election_screen.dart';
import 'package:astro_core/astro_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'widget_test.dart' show wrap;

void main() {
  test('ics: one VEVENT per window, UTC times, escaped text, CRLF', () {
    final jd = julianDay(2026, 3, 4, 9.5);
    final s = buildIcs([IcsEvent(jd, jd + 40 / 1440, 'Termín: smlouva, podpis', 'Pro: a; b')], now: DateTime.utc(2026, 1, 1));
    expect(s, contains('BEGIN:VCALENDAR\r\n'));
    expect('BEGIN:VEVENT'.allMatches(s).length, 1);
    expect(s, contains('DTSTART:20260304T093000Z'));
    expect(s, contains('DTEND:20260304T101000Z'));
    expect(s, contains('SUMMARY:Termín: smlouva\\, podpis'));
    expect(s, contains('DESCRIPTION:Pro: a\\; b'));
    expect(s.endsWith('END:VCALENDAR\r\n'), isTrue);
  });

  test('moment profile keeps the local wall time of the residence', () {
    const place = GeoLocation(lat: 50.0833, lon: 14.4167, name: 'Praha', zone: 'Europe/Prague');
    final jd = julianDay(2026, 7, 1, 8); // 10:00 CEST
    final p = momentProfile(jd, place, 'x');
    expect(p.birth.moment.hour, 10);
    expect(Chart.compute(p.birth).time.jdUt, closeTo(jd, 1e-6));
    expect(p.catalogId, isNotNull);
  });

  testWidgets('election screen: form, and a health intent offers no search', (t) async {
    t.view.physicalSize = const Size(1170, 2532);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    await t.pumpWidget(wrap(const ElectionScreen()));
    await t.pumpAndSettle();
    expect(find.text('Najdi termín'), findsOneWidget);
    expect(find.text('Hledat'), findsOneWidget);
    await t.tap(find.text('Smlouva, podpis, jednání'));
    await t.pumpAndSettle();
    await t.tap(find.text('Operace, zákrok').last);
    await t.pumpAndSettle();
    expect(find.text('Hledat'), findsNothing);
    expect(find.textContaining('termín nehledá'), findsWidgets);
  });
}
