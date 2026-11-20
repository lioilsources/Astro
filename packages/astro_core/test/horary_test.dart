import 'dart:convert';
import 'dart:math' as math;
import 'dart:io';

import 'package:astro_core/astro_core.dart';
import 'package:test/test.dart';

final book = HoraryBook.fromJson((jsonDecode(File('../../content/rules/horary.json').readAsStringSync()) as Map).cast<String, Object?>());

const jd0 = 2461000.5;
const _place = GeoLocation(lat: 50.0833, lon: 14.4167, name: 'Praha', zone: 'Europe/Prague');

/// A constructed case: equal houses from [asc], planets moving uniformly.
({HoraryChart chart, HorarySky sky}) constructed(double asc, Map<Body, ({double lon, double speed})> pos) {
  // Parked planets that were not given: spread 37° apart from 200°, slow and direct.
  var spare = 0;
  final full = <Body, ({double lon, double speed})>{};
  for (final b in Body.traditional) {
    if (pos.containsKey(b)) {
      full[b] = pos[b]!;
    } else {
      full[b] = (lon: norm360(asc + 101 + 37.0 * spare++), speed: 0.001 * (spare + 1));
    }
  }
  final houses = HouseResult(HouseSystem.equal, [for (var i = 0; i < 12; i++) norm360(asc + 30 * i)], asc, norm360(asc + 270), 0);
  final planets = {for (final b in Body.traditional) b: HoraryPlanet(b, full[b]!.lon, 0, full[b]!.speed, houses.houseOf(full[b]!.lon))};
  final chart = HoraryChart(jd0, _place, houses, planets, true, null);
  return (chart: chart, sky: HorarySky.linear(jd0, full, horizonDays: 200));
}

/// UT of a local apparent (sundial) time on a Julian-calendar date: the hour
/// angle of the true Sun + 12 h equals [clock].
double apparentSolarTime(int y, int m, int d, double clock, double lon) {
  var ut = julianDay(y, m, d, clock - lon / 15, calendar: CalendarKind.julian);
  for (var i = 0; i < 6; i++) {
    final jde = ut + deltaTSeconds(decimalYearOfJd(ut)) / 86400;
    final eps = Ephemeris.trueObliquity(jde) * math.pi / 180;
    final l = Ephemeris.longitude(Body.sun, ut) * math.pi / 180;
    final ra = norm360(math.atan2(math.sin(l) * math.cos(eps), math.cos(l)) * 180 / math.pi);
    final solar = norm360(Ephemeris.apparentSiderealDeg(ut) + lon - ra + 180) / 15;
    var diff = clock - solar;
    if (diff > 12) diff -= 24;
    if (diff < -12) diff += 24;
    ut += diff / 24 * 0.99727;
  }
  return ut;
}

HoraryFacts factsOf(({HoraryChart chart, HorarySky sky}) c, String topic, {String person = 'self'}) =>
    HoraryEngine.facts(c.chart, c.sky, book.topic(topic), book.person(person), book);

void main() {
  group('Lilly tables', () {
    test('every degree has exactly one term ruler and one face ruler; terms of each sign sum to 30°', () {
      for (final s in Sign.values) {
        final terms = lillyTerms[s]!;
        expect(terms.length, 5, reason: s.name);
        var start = 0.0;
        for (final t in terms) {
          expect(t.end, greaterThan(start), reason: '${s.name} terms ascend');
          start = t.end;
        }
        expect(terms.last.end, 30, reason: '${s.name} terms sum to 30°');
        expect(lillyFaces[s]!.length, 3);
        // The five term rulers of a sign are five different planets, none a luminary.
        expect(terms.map((t) => t.ruler).toSet().length, 5, reason: s.name);
        expect(terms.any((t) => t.ruler.isLuminary), isFalse);
      }
      for (var tenth = 0; tenth < 3600; tenth++) {
        final lon = tenth / 10 + 0.05;
        final s = Sign.ofLongitude(lon);
        final within = lon % 30;
        var start = 0.0, hits = 0;
        Body? ruler;
        for (final t in lillyTerms[s]!) {
          if (within >= start && within < t.end) {
            hits++;
            ruler = t.ruler;
          }
          start = t.end;
        }
        expect(hits, 1, reason: 'term at $lon');
        expect(termRuler(lon), ruler);
        expect(faceRuler(lon), lillyFaces[s]![(within ~/ 10)]);
      }
    });

    test('faces follow the Chaldean order without a break from Aries to Pisces', () {
      final seq = [for (final s in Sign.values) ...lillyFaces[s]!];
      for (var i = 1; i < seq.length; i++) {
        expect(chaldeanOrder.indexOf(seq[i]), (chaldeanOrder.indexOf(seq[i - 1]) + 1) % 7, reason: 'face $i');
      }
    });

    test('triplicity rulers by day and night exist for every element', () {
      for (final s in Sign.values) {
        expect(triplicityRuler(s, isDay: true), isNotNull);
        expect(triplicityRuler(s, isDay: false), isNotNull);
      }
    });

    test('combustion limits and moieties', () {
      expect(solarCondition(10.0, 10.2), SolarCondition.cazimi);
      expect(solarCondition(10.0, 18.0), SolarCondition.combust);
      expect(solarCondition(10.0, 25.0), SolarCondition.underBeams);
      expect(solarCondition(10.0, 40.0), SolarCondition.free);
      for (final b in Body.traditional) {
        expect(lillyMoiety(b), greaterThan(0));
        expect(lillyMeanMotion[b], greaterThan(0));
      }
    });

    test('every fortitude id used by the engine has points', () {
      for (final id in lillyFortitudes.keys) {
        expect(lillyFortitudes[id], isNot(0), reason: id);
      }
      for (final id in [
        'domicile', 'exaltation', 'triplicity', 'term', 'face', 'detriment', 'fall', 'peregrine', 'house_1_10', 'house_4_7_11',
        'house_2_5', 'house_9', 'house_3', 'house_12', 'house_6_8', 'direct', 'retrograde', 'swift', 'slow', 'cazimi', 'combust',
        'under_beams', 'free_from_combustion',
      ]) {
        expect(lillyFortitudes.containsKey(id), isTrue, reason: id);
      }
    });
  });

  group('motion', () {
    test('applying and separating on constructed positions', () {
      final sky = HorarySky.linear(jd0, {
        Body.mars: (lon: 10, speed: 0.6),
        Body.venus: (lon: 6, speed: 1.2),
        Body.mercury: (lon: 14, speed: 1.5),
      });
      expect(sky.aspectNow(Body.venus, Body.mars)!.applying, isTrue);
      expect(sky.aspectNow(Body.mercury, Body.mars)!.applying, isFalse);
      expect(sky.aspectNow(Body.venus, Body.mars)!.type, AspectType.conjunction);
    });

    test('perfection before a sign change counts, after it does not', () {
      final before = HorarySky.linear(jd0, {Body.venus: (lon: 20, speed: 1.2), Body.mars: (lon: 25, speed: 0.5)});
      final p = before.perfection(Body.venus, Body.mars)!;
      expect(p.type, AspectType.conjunction);
      expect(p.jd - jd0, closeTo(5 / 0.7, 0.01));
      expect(p.degrees, closeTo(5, 1e-6));

      final after = HorarySky.linear(jd0, {Body.venus: (lon: 20, speed: 1.0), Body.mars: (lon: 28, speed: 0.6)});
      expect(after.perfection(Body.venus, Body.mars), isNull, reason: 'Mars leaves Aries after 3.3 days, the conjunction comes after 20');
      expect(after.perfection(Body.venus, Body.mars, until: jd0 + 30)!.jd - jd0, closeTo(20, 0.01));
    });
  });

  group('decision tree on constructed charts', () {
    test('direct perfection by trine: yes; by square without reception: yes with difficulties', () {
      // ASC 15° Taurus: Venus rules the querent, Aquarius on the 10th: Saturn the career.
      final trine = factsOf(
        constructed(45, {
          Body.venus: (lon: 70, speed: 1.2), // 10° Gemini
          Body.saturn: (lon: 315, speed: 0.05), // 15° Aquarius: trine in ~4.3 days
          Body.moon: (lon: 149, speed: 13), // 29° Leo, leaves before any aspect
        }),
        'career',
      );
      expect(trine.querent, Body.venus);
      expect(trine.quesited, Body.saturn);
      expect(trine.route, PerfectionRoute.direct);
      expect(trine.perfection!.type, AspectType.trine);
      expect(HoraryEngine.verdictOf(trine), HoraryVerdict.yes);

      // Square, both in their own terms (Venus 16° Gemini, Saturn 20° Virgo), no reception.
      final square = factsOf(
        constructed(45, {
          Body.venus: (lon: 76, speed: 1.2),
          Body.saturn: (lon: 170, speed: 0.05),
          Body.jupiter: (lon: 300, speed: 0.1),
          Body.moon: (lon: 149, speed: 13),
        }),
        'career',
      );
      expect(square.perfection!.type, AspectType.square);
      expect(square.reception, isFalse);
      expect(square.bothDignified, isTrue);
      expect(HoraryEngine.verdictOf(square), HoraryVerdict.yesDifficult);

      // The same square with Venus peregrine (10° Gemini): Lilly's square does not perfect.
      final blocked = factsOf(
        constructed(45, {
          Body.venus: (lon: 70, speed: 1.2),
          Body.saturn: (lon: 164, speed: 0.05),
          Body.jupiter: (lon: 300, speed: 0.1),
          Body.moon: (lon: 149, speed: 13),
        }),
        'career',
      );
      expect(blocked.perfection!.type, AspectType.square);
      expect(blocked.hardBlocked, isTrue);
      expect(HoraryEngine.verdictOf(blocked), HoraryVerdict.no);
    });

    test('prohibition: a third planet reaches the quesited first', () {
      final f = factsOf(
        constructed(45, {
          Body.venus: (lon: 70, speed: 1.2), // 10° Gemini
          Body.saturn: (lon: 80, speed: 0.05), // 20° Gemini
          // 13° Gemini, faster than Venus: meets Saturn after 4.5 days, Venus would need 8.7.
          Body.mercury: (lon: 73, speed: 1.6),
          Body.moon: (lon: 149, speed: 13),
        }),
        'career',
      );
      expect(f.cancellation, Cancellation.prohibition);
      expect(f.obstacle, Body.mercury);
      expect(HoraryEngine.verdictOf(f), HoraryVerdict.nothing);
    });

    test('frustration: the quesited runs to a third, heavier planet first', () {
      // ASC 15° Taurus, 7th Scorpio: Mars the partner.
      final f = factsOf(
        constructed(45, {
          Body.venus: (lon: 70, speed: 1.2),
          Body.mars: (lon: 78, speed: 0.6),
          Body.saturn: (lon: 82, speed: 0.05),
          Body.moon: (lon: 149, speed: 13),
        }),
        'partner',
      );
      expect(f.quesited, Body.mars);
      expect(f.cancellation, Cancellation.frustration);
      expect(f.obstacle, Body.saturn);
    });

    test('translation of light by Mercury', () {
      // ASC 15° Sagittarius: Jupiter the querent; Capricorn on the 2nd: Saturn the money.
      final f = factsOf(
        constructed(255, {
          Body.jupiter: (lon: 2, speed: 0.2), // 2° Aries
          Body.saturn: (lon: 85, speed: 0.1), // 25° Gemini: no aspect before Jupiter leaves Aries
          // 4° Aries, in Jupiter's term (received by term, CA p. 126): just past
          // Jupiter, applies to Saturn's sextile before meeting anyone else.
          Body.mercury: (lon: 4, speed: 1.5),
          Body.moon: (lon: 148, speed: 13), // 28° Leo, leaves before any aspect
          Body.sun: (lon: 300, speed: 1.0),
        }),
        'money',
      );
      expect(f.querent, Body.jupiter);
      expect(f.quesited, Body.saturn);
      expect(f.route, PerfectionRoute.translation);
      expect(f.mediator, Body.mercury);
      expect(HoraryEngine.verdictOf(f), HoraryVerdict.yes);
    });

    test('collection of light by Saturn standing in dignities of both', () {
      // ASC 15° Libra: Venus the querent, Aries on the 7th: Mars the partner.
      // Saturn at 26° Libra: Venus's house and Mars's term (CA p. 126:
      // "they both receive him in some of their essentiall dignities").
      final f = factsOf(
        constructed(195, {
          Body.venus: (lon: 115, speed: 1.2), // 25° Cancer: square to Saturn in 0.9 days
          Body.mars: (lon: 82, speed: 0.6), // 22° Gemini: trine to Saturn in 7.3 days
          Body.saturn: (lon: 206, speed: 0.05),
          Body.moon: (lon: 89, speed: 13), // 29° Gemini
        }),
        'partner',
      );
      expect(f.querent, Body.venus);
      expect(f.quesited, Body.mars);
      expect(f.route, PerfectionRoute.collection);
      expect(f.mediator, Body.saturn);
    });

    test('separating significators: the matter is past', () {
      final f = factsOf(
        constructed(45, {
          Body.venus: (lon: 72, speed: 1.2),
          Body.saturn: (lon: 70, speed: 0.05),
          Body.moon: (lon: 149, speed: 13),
        }),
        'career',
      );
      expect(f.perfection, isNull);
      expect(f.separating, isNotNull);
      expect(HoraryEngine.verdictOf(f), HoraryVerdict.past);
    });

    test('derived houses: the brother’s work is the 12th', () {
      expect(derivedHouse(3, 10), 12);
      expect(derivedHouse(1, 7), 7);
      expect(derivedHouse(7, 2), 8);
      expect(derivedHouse(10, 4), 1);
      final f = factsOf(constructed(45, {Body.moon: (lon: 149, speed: 13)}), 'career', person: 'sibling');
      expect(f.quesitedHouse, 12);
      expect(f.querent, Body.moon, reason: '3rd cusp Cancer');
      expect(f.quesited, Body.mars, reason: '12th cusp Aries');
      expect(f.coQuerent, isNull);
    });
  });

  test('refranation on a real station of Mercury (29 June 2026)', () {
    // Mercury at 25°55′ Cancer applies to Jupiter at 29°15′ Cancer and turns
    // retrograde on 29 June 2026 before the conjunction is exact.
    final jd = julianDay(2026, 6, 26, 17.6);
    final sky = HorarySky.build(jd, horizonDays: 60);
    expect(sky.aspectNow(Body.mercury, Body.jupiter)!.applying, isTrue);
    expect(sky.perfection(Body.mercury, Body.jupiter), isNull);
    final st = sky.station(Body.mercury, jd, sky.signExit(Body.mercury))!;
    expect(st - jd, closeTo(3, 0.3));
    // As a judgement: ASC Virgo (Mercury) asking about the 7th (Pisces, Jupiter).
    final chart = HoraryChart.at(jd, _place);
    final houses = HouseResult(HouseSystem.equal, [for (var i = 0; i < 12; i++) norm360(165.0 + 30 * i)], 165, 75, 0);
    final c = HoraryChart(jd, _place, houses, {
      for (final b in Body.traditional) b: HoraryPlanet(b, chart[b].lon, 0, chart[b].speed, houses.houseOf(chart[b].lon)),
    }, chart.isDay, null);
    final f = HoraryEngine.facts(c, sky, book.topic('partner'), HoraryPerson.self, book);
    expect(f.querent, Body.mercury);
    expect(f.quesited, Body.jupiter);
    if (f.route == null) {
      expect(f.cancellation, Cancellation.refranation);
      expect(HoraryEngine.verdictOf(f), HoraryVerdict.nothing);
    }
  });

  group('worked examples of Lilly, recomputed (Julian calendar, local apparent time)', () {
    // Lilly's clock times are local apparent (sundial) time; England used the
    // Julian calendar. Positions of 1647 come from the Rudolphine tables, so
    // the tolerances are about a degree for the Moon and the angles.
    void near(double ours, double sign, double deg, double min, double tol, String what) =>
        expect(angDist(ours, sign * 30 + deg + min / 60), lessThan(tol), reason: what);

    test('"Fish stolen", CA II.LIV pp. 397–399: 10 Feb 1637/8, 8:45 a.m., Walton-on-Thames', () {
      final jd = apparentSolarTime(1638, 2, 10, 8.75, -0.417);
      const walton = GeoLocation(lat: 51.383, lon: -0.417, name: 'Walton-on-Thames');
      final c = HoraryChart.at(jd, walton);
      // Lilly's figure (p. 397).
      near(c.asc, 1, 4, 27, 1, 'ASC ♉ 4:27');
      near(c.houses.cusps![1], 2, 13, 28, 1, '2nd ♊ 13:28');
      near(c.houses.cusps![2], 3, 1, 2, 1, '3rd ♋ 1:02');
      near(c.houses.mc, 9, 14, 0, 1, 'MC ♑ 14');
      near(c.houses.cusps![10], 9, 29, 33, 1, '11th ♑ 29:33');
      near(c.houses.cusps![11], 11, 0, 33, 1, '12th ♓ 0:33');
      near(c[Body.sun].lon, 11, 2, 0, 0.5, '☉ ♓ 2:00');
      near(c[Body.moon].lon, 1, 15, 3, 0.5, '☽ ♉ 15:03');
      near(c[Body.mercury].lon, 11, 18, 0, 0.5, '☿ ♓ 18:00');
      near(c[Body.venus].lon, 0, 18, 20, 0.5, '♀ ♈ 18:20');
      near(c[Body.mars].lon, 7, 29, 50, 0.5, '♂ ♏ 29:50');
      near(c[Body.jupiter].lon, 7, 5, 3, 0.5, '♃ ♏ 5:03');
      near(c[Body.saturn].lon, 10, 1, 46, 0.5, '♄ ♒ 1:46');
      expect(c[Body.jupiter].house, 7, reason: '"♃ … upon the cusp of the seventh house"');

      final f = HoraryEngine.facts(c, HorarySky.build(jd), book.topic('lost_object'), HoraryPerson.self, book);
      // "☿ Lord of my house of Substance, was applyed unto by a ✶ of ☽" (p. 398).
      expect(f.querent, Body.venus);
      expect(f.quesited, Body.mercury);
      expect(f.route, PerfectionRoute.moon);
      expect(f.perfection!.type, AspectType.sextile);
      // "☿ Lord of my second, was in his fall and detriment, but … in his own Termes".
      final m = f.strength[Body.mercury]!;
      expect(m.has('fall') && m.has('detriment') && m.has('term'), isTrue);
      // "there was no peregrine Planet in angle but ♃" (p. 397).
      expect(f.strength[Body.jupiter]!.has('peregrine'), isTrue);
      expect(HoraryEngine.verdictOf(f), HoraryVerdict.yes, reason: 'Lilly: "I should heare of my Goods againe" and found part of them');
    });

    test('"A Lady, if marry the Gentleman desired?", CA II.LIX pp. 385–388: 16 June 1646, 19:26 p.m. (astronomical)', () {
      // Astronomical 16 June 19h26m = civil 17 June 7:26 a.m.; place not printed, London assumed.
      final jd = apparentSolarTime(1646, 6, 17, 7 + 26 / 60, -0.12);
      const london = GeoLocation(lat: 51.5, lon: -0.12, name: 'London');
      final c = HoraryChart.at(jd, london);
      near(c.asc, 4, 17, 11, 1.5, 'ASC ♌ 17:11');
      near(c.houses.mc, 1, 1, 0, 1.5, 'MC ♉ 1:00');
      near(c[Body.sun].lon, 3, 5, 31, 0.5, '☉ ♋ 5:31');
      near(c[Body.moon].lon, 8, 28, 9, 1.0, '☽ ♐ 28:09');
      near(c[Body.mercury].lon, 2, 15, 55, 0.7, '☿ ♊ 15:55');
      near(c[Body.venus].lon, 1, 20, 11, 0.5, '♀ ♉ 20:11');
      near(c[Body.mars].lon, 1, 17, 40, 0.5, '♂ ♉ 17:40');
      near(c[Body.jupiter].lon, 3, 14, 40, 0.5, '♃ ♋ 14:40');
      near(c[Body.saturn].lon, 1, 14, 53, 0.5, '♄ ♉ 14:53');
      expect(c.hourRuler, Body.saturn, reason: '"Hor: astr: ♄"');

      final f = HoraryEngine.facts(c, HorarySky.build(jd), book.topic('partner'), HoraryPerson.self, book, moonVoid: true);
      // "The ascendant and ☉ are for the querent; ♄ Lord of the seventh, is for the man".
      expect(f.querent, Body.sun);
      expect(f.quesited, Body.saturn);
      // "the application of the two Significators to a ✶", perfected "the 27th of the same moneth".
      expect(f.route, PerfectionRoute.direct);
      expect(f.perfection!.type, AspectType.sextile);
      final when = calendarFromJd(f.perfection!.jd, calendar: CalendarKind.julian);
      expect((month: when.month, day: when.day.floor()), anyOf((month: 6, day: 27), (month: 6, day: 28)));
      // "there was no Reception betwixt the significators".
      expect(f.reception, isFalse);
      // "♃ … receiving his vertue which ♄ did render unto him … transferred to the ☉".
      expect(f.mediator, Body.jupiter);
      expect(f.cancellation, isNull);
      expect(HoraryEngine.verdictOf(f), HoraryVerdict.yes, reason: 'Lilly: "the Match effected"');
      // "☽ a vac:" — void of course in the figure.
      final timeline = MoonAspectTimeline.build(jd - 0.5, jd + 0.5, traditionalOnly: true);
      expect(timeline.voidAt(jd), isNotNull);
    });
  });

  group('considerations', () {
    test('ASC at 2° of a sign gives the early-ascendant warning', () {
      final c = constructed(32, const {});
      final ctx = HoraryContext(c.chart, c.sky, null, MoonAspectTimeline.build(jd0 - 0.5, jd0 + 0.5, traditionalOnly: true));
      final fired = evaluateRules(book.considerations, horaryPredicates, ctx).fired.map((r) => r.id);
      expect(fired, contains('asc_early'));
      expect(fired, isNot(contains('asc_late')));
      final c2 = constructed(45, const {});
      final f2 = evaluateRules(book.considerations, horaryPredicates, HoraryContext(c2.chart, c2.sky, null, ctx.moonTimeline)).fired.map((r) => r.id);
      expect(f2, isNot(contains('asc_early')));
    });
  });

  test('same moment, place and topic give the same verdict', () {
    const q = HoraryQuestion(jdUt: 2461180.25, place: _place, topic: 'career');
    final a = HoraryEngine.judge(q, book), b = HoraryEngine.judge(q, book);
    expect(a.verdict, b.verdict);
    expect(a.plus.map((r) => r.id), b.plus.map((r) => r.id));
    expect(a.minus.map((r) => r.id), b.minus.map((r) => r.id));
    expect(a.considerations.map((r) => r.id), b.considerations.map((r) => r.id));
    expect(a.facts!.perfection?.jd, b.facts!.perfection?.jd);
    expect(a.chart.houses.system, HouseSystem.regiomontanus);
  });

  test('health, death and pregnancy get no verdict (owner decision 20)', () {
    for (final t in ['health', 'death', 'pregnancy']) {
      final j = HoraryEngine.judge(HoraryQuestion(jdUt: 2461180.25, place: _place, topic: t), book);
      expect(j.verdict, isNull, reason: t);
      expect(j.plus, isEmpty);
      expect(j.minus, isEmpty);
    }
  });

  test('inside the polar circle the houses are Porphyry', () {
    final c = HoraryChart.at(2461180.25, const GeoLocation(lat: 69.65, lon: 18.96, name: 'Tromsø'));
    expect(c.houses.system, HouseSystem.porphyry);
  });

  test('lost object gets a direction by sign and by house', () {
    final j = HoraryEngine.judge(const HoraryQuestion(jdUt: 2461180.25, place: _place, topic: 'lost_object'), book);
    expect(j.lost, isNotNull);
    expect(j.lost!.bySign, isNotEmpty);
    expect(j.lost!.byHouse, isNotEmpty);
  });
}
