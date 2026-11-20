import 'dart:convert';
import 'dart:isolate';

import 'package:astro_core/astro_core.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/profile.dart';

/// Election rules bundled from `content/rules/election.json` (plan 10.7).
final electionRulesProvider = FutureProvider<RuleBook>((ref) async =>
    RuleBook.fromJson((jsonDecode(await rootBundle.loadString('assets/rules/election.json')) as Map).cast<String, Object?>()));

/// Runs the election search off the UI thread (90 days ≈ 1 s).
Future<ElectionResult> searchElection(ElectionQuery q, RuleBook book) => Isolate.run(() => ElectionSearch.run(q, book));

/// A read-only profile for the chart of one moment at [place] (tap on a window).
Profile momentProfile(double jdUt, GeoLocation place, String name) {
  final t = localTime(jdUt, place);
  return Profile(
    id: 'election-${jdUt.toStringAsFixed(5)}',
    name: name,
    birth: BirthData(
      moment: LocalMoment(
        year: t.year,
        month: t.month,
        day: t.day,
        hour: t.hour,
        minute: t.minute,
        zone: place.zone,
        basis: place.zone == null ? TimeBasis.lmt : TimeBasis.zone,
      ),
      lat: place.lat,
      lon: place.lon,
      placeName: place.name,
    ),
    catalogId: 'election',
    residence: place,
  );
}
