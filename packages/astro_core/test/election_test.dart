import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:astro_core/astro_core.dart';
import 'package:test/test.dart';

RuleBook loadBook() =>
    RuleBook.fromJson((jsonDecode(File('../../content/rules/election.json').readAsStringSync()) as Map).cast<String, Object?>());

const prague = GeoLocation(lat: 50.0833, lon: 14.4167, name: 'Praha', zone: 'Europe/Prague');

ElectionQuery query({int days = 14, Chart? natal, ElectionIntent intent = ElectionIntent.contract, Set<int>? hours, Set<int>? weekdays}) =>
    ElectionQuery(intent: intent, year: 2026, month: 3, day: 1, days: days, place: prague, natal: natal, hours: hours, weekdays: weekdays);

void main() {
  final book = loadBook();

  test('rule file: every rule has a weight, a text key and a known condition', () {
    expect(book.rules.length, greaterThanOrEqualTo(25));
    for (final r in book.rules) {
      expect(electionConditions, contains(r.when), reason: r.id);
      expect(r.textKey, 'election/rule/${r.id}');
      if (r.kind != RuleKind.exclude) expect(r.weight, greaterThan(0), reason: r.id);
    }
    expect(book.rules.where((r) => r.kind == RuleKind.exclude).map((r) => r.id), ['moon_void']);
    expect(book.rules.map((r) => r.id).toSet().length, book.rules.length);
  });

  test('timeline voids equal Lunar.voidOfCourse', () {
    final from = 2461100.5, to = from + 30;
    final mine = MoonAspectTimeline.build(from, to).voids;
    final r2 = Lunar.voidOfCourse(from, to);
    expect(mine.length, r2.length);
    for (var i = 0; i < mine.length; i++) {
      expect(mine[i].start, closeTo(r2[i].start, 1e-9));
      expect(mine[i].end, closeTo(r2[i].end, 1e-9));
    }
  });

  test('next aspect is the first perfection after the moment, within the sign', () {
    final from = 2461100.5;
    final tl = MoonAspectTimeline.build(from, from + 10);
    for (var t = from; t < from + 10; t += 0.37) {
      final a = tl.nextAspect(t);
      if (a == null) {
        expect(tl.voidAt(t), isNotNull, reason: 'no next aspect only when void at $t');
      } else {
        expect(a.jd, greaterThan(t));
        expect(Sign.ofLongitude(tl.moon.at(a.jd - 1e-4)), Sign.ofLongitude(tl.moon.at(t)));
        expect(tl.voidAt(t), isNull);
      }
    }
  });

  test('planetary hour spans agree with PlanetaryHours.hourAt', () {
    final from = 2461100.5;
    final spans = planetaryHourSpans(from, from + 5, prague.lat, prague.lon);
    for (var t = from + 0.05; t < from + 5; t += 0.29) {
      final mine = spans.where((h) => h.covers(t)).first;
      final r2 = PlanetaryHours.hourAt(t, prague.lat, prague.lon)!;
      expect(mine.ruler, r2.ruler, reason: '$t');
      expect(mine.number, r2.number);
    }
  });

  test('a void-of-course window is never returned', () {
    final r = ElectionSearch.run(query(days: 30), book);
    final voids = Lunar.voidOfCourse(r.from, r.to);
    expect(voids, isNotEmpty);
    for (final w in [...r.windows, ...r.all]) {
      for (final v in voids) {
        expect(w.start < v.end && w.end > v.start, isFalse, reason: '$w overlaps $v');
      }
      expect(w.outcome.excluded, isFalse);
    }
  });

  test('same input gives the same windows and scores', () {
    final a = ElectionSearch.run(query(), book), b = ElectionSearch.run(query(), book);
    expect([for (final w in a.windows) '${w.start} ${w.end} ${w.score}'], [for (final w in b.windows) '${w.start} ${w.end} ${w.score}']);
  });

  test('adjacent samples with equal outcome merge; neighbours differ', () {
    final r = ElectionSearch.run(query(days: 7), book);
    expect(r.all.length, lessThan(r.samples ~/ 2));
    for (final w in r.all) {
      final k = (w.end - w.start) / ElectionSearch.stepDays;
      expect((k - k.round()).abs(), lessThan(1e-6));
      expect(k.round(), greaterThanOrEqualTo(1));
    }
    for (var i = 0; i + 1 < r.all.length; i++) {
      final a = r.all[i], b = r.all[i + 1];
      expect(a.end <= b.start + 1e-9, isTrue);
      if ((a.end - b.start).abs() < 1e-9) expect(a.outcome.signature, isNot(b.outcome.signature));
    }
  });

  test('output: at most 10 windows, best first, reasons match the score', () {
    final r = ElectionSearch.run(query(days: 30), book);
    expect(r.windows.length, inInclusiveRange(1, 10));
    for (var i = 0; i + 1 < r.windows.length; i++) {
      expect(r.windows[i].score, greaterThanOrEqualTo(r.windows[i + 1].score));
    }
    for (final w in r.windows) {
      expect(w.plus.fold<int>(0, (s, x) => s + x.weight) - w.minus.fold<int>(0, (s, x) => s + x.weight), w.score);
    }
  });

  test('hour and weekday constraints are respected', () {
    final r = ElectionSearch.run(query(days: 14, hours: {9, 10, 11}, weekdays: {DateTime.tuesday}), book);
    for (final w in r.all) {
      for (var t = w.start; t < w.end - 1e-9; t += ElectionSearch.stepDays) {
        final l = localTime(t, prague);
        expect(l.weekday, DateTime.tuesday);
        expect({9, 10, 11}, contains(l.hour));
      }
    }
  });

  test('nothing passes → least bad window is returned, flagged', () {
    final strict = RuleBook(book.version, book.rules, const {'strong': 1000});
    final r = ElectionSearch.run(query(days: 3), strict);
    expect(r.anyPassed, isFalse);
    expect(r.windows, hasLength(1));
    expect(r.windows.single.passed, isFalse);
    expect(r.windows.single.verdict, 'none');
  });

  test('personal layer adds personal rules only with a profile', () {
    final natal = Chart.compute(const BirthData(
        moment: LocalMoment(year: 1990, month: 6, day: 15, hour: 8, minute: 30, zone: 'Europe/Prague'), lat: 50.0833, lon: 14.4167));
    final sky = ElectionSearch.run(query(days: 7), book);
    final mine = ElectionSearch.run(query(days: 7, natal: natal), book);
    bool hasPersonal(ElectionResult r) => r.all.any((w) => w.outcome.fired.any((x) => x.layer == RuleLayer.personal));
    expect(hasPersonal(sky), isFalse);
    expect(hasPersonal(mine), isTrue);
  });

  test('90 days with a profile run under 2 s in an isolate', () async {
    final natal = Chart.compute(const BirthData(
        moment: LocalMoment(year: 1985, month: 11, day: 2, hour: 14, minute: 10, zone: 'Europe/Prague'), lat: 49.2, lon: 16.6));
    final q = query(days: 90, natal: natal, intent: ElectionIntent.launch);
    final sw = Stopwatch()..start();
    final r = await Isolate.run(() => ElectionSearch.run(q, book));
    sw.stop();
    // ignore: avoid_print
    print('election 90 days: ${sw.elapsedMilliseconds} ms, ${r.samples} samples, ${r.all.length} windows');
    // 90 days minus the hour lost to the spring clock change.
    expect(r.samples, 90 * 144 - 6);
    expect(sw.elapsedMilliseconds, lessThan(2000));
  });
}
