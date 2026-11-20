import 'dart:isolate';
import 'dart:math' as math;

import 'package:astro_core/astro_core.dart';
import 'package:astro_core/journal.dart';

/// One dated event of a catalog person (Prompts/KATALOG-osobnosti.md, oddíl 6).
class CatalogEvent {
  final int year, month, day;
  final String label;
  final String type;

  /// What the person is known for (election, premiere, title…), as opposed to ordinary
  /// life events (marriage, club, death).
  final bool defining;
  final String source;
  final String? url;

  /// The Wikipedia sentence the date comes from.
  final String? quote;

  /// Date as written in a Julian-calendar source; [year]/[month]/[day] are Gregorian.
  final String? dateJulian;

  const CatalogEvent({
    required this.year,
    required this.month,
    required this.day,
    required this.label,
    required this.type,
    required this.defining,
    required this.source,
    this.url,
    this.quote,
    this.dateJulian,
  });

  factory CatalogEvent.fromJson(Map<String, Object?> j) {
    final d = (j['date'] as String).split('-').map(int.parse).toList();
    final type = j['type'] as String? ?? 'other';
    return CatalogEvent(
      year: d[0],
      month: d[1],
      day: d[2],
      label: j['label'] as String,
      type: type,
      // Records from before the defining flag: offices, awards and works were the defining kinds.
      defining: j['defining'] as bool? ?? const {'office', 'award', 'work'}.contains(type),
      source: j['source'] as String? ?? '',
      url: j['url'] as String?,
      quote: j['quote'] as String?,
      dateJulian: j['date_julian'] as String?,
    );
  }

  String get date => '$year-${two(month)}-${two(day)}';
  static String two(int v) => v.toString().padLeft(2, '0');

  /// The exact hour of the event is unknown: local noon in the birth place's zone
  /// (local mean time where the zone did not exist yet).
  double noonJd(BirthData birth) => resolveMoment(
        LocalMoment(year: year, month: month, day: day, hour: 12, minute: 0, zone: birth.moment.zone),
        birth.lon,
      ).jdUt;
}

/// Days of a life used for the tension comparison: birth until death (or [now]), at most 100 years.
int lifeDays(Chart natal, double? deathJd, double now) {
  final end = deathJd != null ? math.min(deathJd + 1, now) : now;
  return (end - natal.time.jdUt).clamp(1, 36525).floor();
}

/// Active transit on the event day with its orb.
class EventTransit {
  final TransitEvent event;
  final double orb;
  final int strength;
  const EventTransit(this.event, this.orb, this.strength);
}

/// Where a transiting planet stood on the event day.
class EventPosition {
  final Body body;
  final double lon;
  final bool retrograde;

  /// Natal house it passed through; null without a birth time.
  final int? house;
  const EventPosition(this.body, this.lon, this.retrograde, this.house);
}

/// "Tranzity v den události": transits of the event day and the honest check against the life.
class EventDay {
  final double jd;
  final List<EventPosition> positions;
  final List<EventTransit> transits;
  final double tension;
  final LifeRank rank;
  final int lifeDays;
  const EventDay(this.jd, this.positions, this.transits, this.tension, this.rank, this.lifeDays);
}

/// How unusual a day is within its life, in words (bucket ids for the l10n select).
String unusualness(int percentile) => switch (percentile) {
      < 20 => 'calm',
      < 80 => 'ordinary',
      < 95 => 'tense',
      _ => 'extreme',
    };

EventDay computeEventDay(Chart natal, double jd, double? deathJd, double now) {
  final engine = TransitEngine(natal);
  final active = engine.events(jd - 0.01, jd + 0.01).where((e) => e.covers(jd)).toList();
  final transits = [
    for (final e in active) EventTransit(e, engine.deviationAt(e, jd).abs(), engine.strengthAt(e, jd, concurrent: active)),
  ]..sort((a, b) => b.strength.compareTo(a.strength));
  final positions = <EventPosition>[];
  for (final b in Body.planets) {
    if (!Ephemeris.available(b, jd)) continue;
    final lon = Ephemeris.longitude(b, jd);
    final speed = angDiff(Ephemeris.longitude(b, jd + 0.5), Ephemeris.longitude(b, jd - 0.5));
    positions.add(EventPosition(b, lon, speed < 0, natal.houses?.houseOf(lon)));
  }
  final days = lifeDays(natal, deathJd, math.max(now, jd + 1));
  final prof = engine.tensionProfile(natal.time.jdUt, days, [jd]);
  final sorted = [...prof.series]..sort();
  return EventDay(jd, positions, transits, prof.at.single, lifeRank(sorted, prof.at.single), days);
}

/// Input of the catalog-wide check: one person's chart, death and defining event moments.
class LifeInput {
  final Chart natal;
  final double? deathJd;
  final List<double> eventJds;
  const LifeInput(this.natal, this.deathJd, this.eventJds);
}

/// Ranks of one life's event days and the reference pool of that life.
List<EventDaySample> lifeSamples(LifeInput p, double now, {double stepScale = 2}) {
  final days = lifeDays(p.natal, p.deathJd, now);
  final from = p.natal.time.jdUt;
  final inside = [for (final jd in p.eventJds) if (jd > from && jd < from + days) jd];
  if (inside.isEmpty) return const [];
  final prof = TransitEngine(p.natal).tensionProfile(from, days, inside, stepScale: stepScale);
  if (prof.series.every((v) => v == prof.series.first)) return const []; // no ephemeris coverage
  final sorted = [...prof.series]..sort();
  final pool = lifePool(prof.series);
  return [for (final t in prof.at) EventDaySample(lifeRank(sorted, t), pool)];
}

class CatalogCheck {
  final EventDaySummary? summary;
  final int people;
  const CatalogCheck(this.summary, this.people);
}

/// Catalog-wide check of all defining events, split over a few isolates.
Future<CatalogCheck> computeCatalogCheck(List<LifeInput> lives, double now, {int workers = 4}) async {
  final parts = [for (var w = 0; w < workers; w++) [for (var i = w; i < lives.length; i += workers) lives[i]]];
  final results = await Future.wait([
    for (final part in parts) Isolate.run(() => [for (final p in part) lifeSamples(p, now)]),
  ]);
  final perLife = [for (final r in results) ...r];
  final samples = [for (final s in perLife) ...s];
  final people = perLife.where((s) => s.isNotEmpty).length;
  final summary = await Isolate.run(() => summarizeEventDays(samples));
  return CatalogCheck(summary, people);
}
