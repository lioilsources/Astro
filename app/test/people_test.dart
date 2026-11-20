import 'dart:convert';
import 'dart:io';

import 'package:astro/ui/people_screen.dart';
import 'package:astro_core/astro_core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final raw = (jsonDecode(File('assets/data/people.json').readAsStringSync()) as List).cast<Map>();

  test('the app copy of the catalog matches content/people', () {
    expect(File('assets/data/people.json').readAsStringSync(), File('../content/people/people.json').readAsStringSync());
  });

  test('every catalog record parses and resolves to a moment', () {
    for (final j in raw) {
      final p = Person.fromJson(j.cast<String, Object?>());
      final t = resolveMoment(p.profile.birth.moment, p.profile.birth.lon);
      expect(t.jdUt.isFinite, isTrue, reason: p.id);
      expect(p.profile.catalogReliability, p.reliability);
      expect(p.profile.birth.moment.timeKnown, p.reliability != 'X', reason: p.id);
    }
  });
}
