import 'dart:io' show Platform;
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

/// Coarser ephemeris sampling for the catalog-wide check (documented in the method note).
const catalogStepScale = 2.0;

/// Ranks of one life's event days and the reference pool of that life.
List<EventDaySample> lifeSamples(LifeInput p, double now, {Map<Body, LongitudeTrack> shared = const {}}) {
  final days = lifeDays(p.natal, p.deathJd, now);
  final from = p.natal.time.jdUt;
  final inside = [for (final jd in p.eventJds) if (jd > from && jd < from + days) jd];
  if (inside.isEmpty) return const [];
  final prof = TransitEngine(p.natal).tensionProfile(from, days, inside, stepScale: catalogStepScale, shared: shared);
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

/// Spans of time covered by the lives (merged when closer than [gapDays]).
List<({double from, double to})> lifeSpans(List<LifeInput> lives, double now, {double gapDays = 3650}) {
  final spans = [
    for (final p in lives) (from: p.natal.time.jdUt, to: p.natal.time.jdUt + lifeDays(p.natal, p.deathJd, now)),
  ]..sort((a, b) => a.from.compareTo(b.from));
  final out = <({double from, double to})>[];
  for (final s in spans) {
    if (out.isNotEmpty && s.from <= out.last.to + gapDays) {
      out.last = (from: out.last.from, to: math.max(out.last.to, s.to));
    } else {
      out.add(s);
    }
  }
  return out;
}

/// Catalog-wide check of all defining events. The ephemeris pass is shared: one track per
/// planet and span of lives (Pluto per life, its tables do not cover every century), built
/// in parallel isolates; the lives are then scored in parallel isolates.
Future<CatalogCheck> computeCatalogCheck(List<LifeInput> lives, double now, {int? workers}) async {
  final w = workers ?? Platform.numberOfProcessors.clamp(2, 8);
  final spans = lifeSpans(lives, now);
  final bodies = [for (final b in Body.planets) if (b != Body.moon && b != Body.pluto) b];
  // Pieces of about 40 years on one sampling grid per body, built in parallel and joined.
  final jobs = <({int span, Body body, double from, double to, double step})>[];
  for (var si = 0; si < spans.length; si++) {
    final s = spans[si];
    for (final b in bodies) {
      final step = TransitEngine.tensionStepDays(b, stepScale: catalogStepScale);
      final piece = step * (40 * 365.25 / step).ceil();
      for (var a = s.from; a < s.to; a += piece) {
        jobs.add((span: si, body: b, from: a, to: math.min(a + piece, s.to), step: step));
      }
    }
  }
  final pieces = <LongitudeTrack>[];
  for (var i = 0; i < jobs.length; i += w) {
    final batch = jobs.sublist(i, math.min(i + w, jobs.length));
    pieces.addAll(await Future.wait([
      for (final j in batch) _trackIn(j.body, j.from, j.to, j.step),
    ]));
  }
  final built = <({double from, double to, Body body, LongitudeTrack track})>[];
  for (var si = 0; si < spans.length; si++) {
    for (final b in bodies) {
      final parts = [for (var i = 0; i < jobs.length; i++) if (jobs[i].span == si && jobs[i].body == b) pieces[i]];
      built.add((from: spans[si].from, to: spans[si].to, body: b, track: LongitudeTrack.joined(parts)));
    }
  }
  Map<Body, LongitudeTrack> sharedFor(LifeInput p) {
    final from = p.natal.time.jdUt;
    return {
      for (final t in built)
        if (t.from <= from && from <= t.to) t.body: t.track,
    };
  }

  final parts = [for (var k = 0; k < w; k++) [for (var i = k; i < lives.length; i += w) lives[i]]];
  final results = await Future.wait([
    for (final part in parts) _scoreIn([for (final p in part) (p: p, shared: sharedFor(p))], now),
  ]);
  // Back to catalog order, so the result does not depend on the number of isolates.
  final perLife = [for (var i = 0; i < lives.length; i++) results[i % w][i ~/ w]];
  final samples = [for (final s in perLife) ...s];
  final people = perLife.where((s) => s.isNotEmpty).length;
  final summary = await _summarizeIn(samples);
  return CatalogCheck(summary, people);
}

// Top-level helpers so the isolate closures capture only their arguments.
Future<LongitudeTrack> _trackIn(Body body, double from, double to, double step) =>
    Isolate.run(() => LongitudeTrack.build(body, from, to, step));

Future<List<List<EventDaySample>>> _scoreIn(List<({LifeInput p, Map<Body, LongitudeTrack> shared})> inputs, double now) =>
    Isolate.run(() => [for (final x in inputs) lifeSamples(x.p, now, shared: x.shared)]);

Future<EventDaySummary?> _summarizeIn(List<EventDaySample> samples) => Isolate.run(() => summarizeEventDays(samples));
