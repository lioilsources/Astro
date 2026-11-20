import '../aspects.dart';
import '../chart.dart';
import '../model.dart';
import '../moon.dart';
import '../patterns.dart';
import '../stars.dart';
import '../transits.dart';
import 'keys.dart';

enum FactorKind { planetInSign, planetInHouse, aspect, aspectPoint, signOnCusp, emphasis, pattern, star, moonPhase }

/// One interpretable fact of a chart with the key of its text.
class Factor {
  final String key;
  final FactorKind kind;

  /// 0..1: how much the factor weighs in this chart (personal points, tight orbs).
  final double weight;
  final Body? body;
  final Sign? sign;
  final int? house;
  final Aspect? aspect;
  final ChartPattern? pattern;

  /// Star conjunction (kind [FactorKind.star]): the tightest contact of the star.
  final StarContact? star;
  const Factor(this.key, this.kind, this.weight, {this.body, this.sign, this.house, this.aspect, this.pattern, this.star});
  @override
  String toString() => '$key (${weight.toStringAsFixed(2)})';
}

const _bodyWeight = {
  Body.sun: 1.0, Body.moon: 1.0, Body.mercury: 0.8, Body.venus: 0.8, Body.mars: 0.8,
  Body.jupiter: 0.6, Body.saturn: 0.6, Body.uranus: 0.4, Body.neptune: 0.4, Body.pluto: 0.4,
  Body.meanNode: 0.4, Body.trueNode: 0.4,
};

double _pointWeight(ChartPoint p) => p.isAngle ? (p.angle == Angle.asc ? 1.0 : 0.8) : _bodyWeight[p.body]!;

String qualityId(AspectType t) => t.quality.name;

/// Content key of a natal aspect, or null when no text family covers it (node–angle).
String? aspectKey(Aspect a) {
  var x = a.a, y = a.b;
  final xPoint = x.isAngle || (x.body?.isNode ?? false);
  final yPoint = y.isAngle || (y.body?.isNode ?? false);
  if (xPoint && yPoint) return null;
  if (xPoint || yPoint) {
    final point = xPoint ? x : y;
    final planet = xPoint ? y : x;
    return 'aspect_point/${point.isAngle ? point.angle!.name : 'node'}/${planet.body!.name}/${qualityId(a.type)}';
  }
  if (planetIds.indexOf(x.body!.name) > planetIds.indexOf(y.body!.name)) (x, y) = (y, x);
  return 'aspect/${x.body!.name}/${y.body!.name}/${a.type.name}';
}

/// All factors of a natal chart in reading order (plan 2: sign, house, aspect, cusp).
List<Factor> factorsOf(Chart c) {
  final out = <Factor>[];
  for (final b in c.bodies) {
    final p = c.positions[b]!;
    out.add(Factor('planet_in_sign/${contentIdOf(b)}/${p.sign.name}', FactorKind.planetInSign, _bodyWeight[b]!, body: b, sign: p.sign));
  }
  for (final b in c.bodies) {
    final h = c.houseOf(b);
    if (h != null) out.add(Factor('planet_in_house/${contentIdOf(b)}/$h', FactorKind.planetInHouse, _bodyWeight[b]! * 0.9, body: b, house: h));
  }
  for (final a in c.aspects) {
    final k = aspectKey(a);
    if (k == null) continue;
    final w = (_pointWeight(a.a) + _pointWeight(a.b)) / 2 * (0.5 + 0.5 * a.exactness);
    out.add(Factor(k, k.startsWith('aspect_point') ? FactorKind.aspectPoint : FactorKind.aspect, w, aspect: a));
  }
  final cusps = c.houses?.cusps;
  if (cusps != null) {
    for (var i = 0; i < 12; i++) {
      final s = Sign.ofLongitude(cusps[i]);
      out.add(Factor('sign_on_cusp/${i + 1}/${s.name}', FactorKind.signOnCusp, i == 0 ? 1.0 : (i == 9 ? 0.8 : 0.3), house: i + 1, sign: s));
    }
  }
  out.addAll(emphasisOf(c));
  final phase = natalMoonPhase(c);
  if (phase != null) out.add(Factor(natalMoonPhaseKey(phase), FactorKind.moonPhase, 0.6));
  out.addAll(patternFactorsOf(c));
  out.addAll(starFactorsOf(c));
  return out;
}

/// Content keys of one pattern: a T-square has the shape and its apex, a yod only its apex.
List<String> patternKeysOf(ChartPattern p) => switch (p.kind) {
      PatternKind.grandTrine => ['pattern/grand_trine/${p.element!.name}'],
      PatternKind.tSquare => [
          'pattern/t_square/${p.modality!.name}',
          for (final b in p.apexes) 'pattern/t_square_apex/${b.name}',
        ],
      PatternKind.grandCross => ['pattern/grand_cross/${p.modality!.name}'],
      PatternKind.yod => [for (final b in p.apexes) 'pattern/yod_apex/${b.name}'],
      PatternKind.kite => ['pattern/kite/${p.element!.name}'],
      PatternKind.cradle => ['pattern/cradle'],
      PatternKind.mysticRectangle => ['pattern/mystic_rectangle'],
      PatternKind.modalityExcess => ['pattern/modality/${p.modality!.name}/excess'],
      PatternKind.modalityLack => ['pattern/modality/${p.modality!.name}/lack'],
      PatternKind.hemisphere => ['pattern/hemisphere/${p.hemisphere!.name}'],
      PatternKind.unaspected => ['pattern/unaspected/${p.bodies.single.name}'],
    };

/// Pattern texts of a chart, each key once (shapes weigh more than counts).
List<Factor> patternFactorsOf(Chart c) {
  final out = <Factor>[];
  final seen = <String>{};
  for (final p in c.patterns) {
    for (final k in patternKeysOf(p)) {
      if (seen.add(k)) out.add(Factor(k, FactorKind.pattern, p.kind.isShape ? 0.8 : 0.6, pattern: p));
    }
  }
  return out;
}

/// One factor per fixed star in conjunction (plan 10.6), from its tightest contact.
List<Factor> starFactorsOf(Chart c) {
  final seen = <String>{};
  return [
    for (final s in c.starContacts)
      if (seen.add(s.star.id))
        Factor('star/${s.star.id}', FactorKind.star, _pointWeight(s.point) * (1 - 0.5 * s.orb / starOrb), star: s),
  ];
}

/// Key of the sentence about a star at a given point (`star_target/{point}`).
String starTargetKey(ChartPoint p) => 'star_target/${p.id}';

/// Stellia (3+ planets in a sign or house) and dominant (5+) or missing (0) elements.
List<Factor> emphasisOf(Chart c) {
  final out = <Factor>[];
  final planets = Body.planets.where(c.positions.containsKey).toList();
  final bySign = <Sign, int>{};
  final byHouse = <int, int>{};
  final byElement = {for (final e in Element.values) e: 0};
  for (final b in planets) {
    final s = c.positions[b]!.sign;
    bySign[s] = (bySign[s] ?? 0) + 1;
    byElement[s.element] = byElement[s.element]! + 1;
    final h = c.houseOf(b);
    if (h != null) byHouse[h] = (byHouse[h] ?? 0) + 1;
  }
  bySign.forEach((s, n) {
    if (n >= 3) out.add(Factor('emphasis/sign/${s.name}', FactorKind.emphasis, 0.7, sign: s));
  });
  byHouse.forEach((h, n) {
    if (n >= 3) out.add(Factor('emphasis/house/$h', FactorKind.emphasis, 0.7, house: h));
  });
  byElement.forEach((e, n) {
    if (n >= 5) out.add(Factor('emphasis/element_dominant/${e.name}', FactorKind.emphasis, 0.7));
    if (n == 0) out.add(Factor('emphasis/element_missing/${e.name}', FactorKind.emphasis, 0.7));
  });
  return out;
}

/// Key of the base text of a transit event.
String transitKey(TransitEvent e) => e.target.isAngle
    ? 'transit_point/${e.transiting.name}/${e.target.angle!.name}/${qualityId(e.type)}'
    : 'transit/${e.transiting.name}/${e.target.body!.name}/${e.type.name}';

String transitInHouseKey(Body b, int house) => 'transit_in_house/${b.name}/$house';

// R2 (plan 10.2): Moon and planetary hours.
String planetaryHourKey(Body ruler) => 'planetary_hour/${ruler.name}';
String planetaryDayKey(Body ruler) => 'planetary_day/${ruler.name}';
String moonPhaseKey(MoonPhase p) => 'moon_phase/${p.id}';
String natalMoonPhaseKey(MoonPhase p) => 'natal_moon_phase/${p.id}';
String moonTodayKey(Sign s) => 'moon_today/${s.name}';
const voidOfCourseKey = 'void_of_course';
String eclipseKey(EclipseKind k) => 'eclipse/${k.name}';

/// Key of a new or full moon in a natal house; null for quarters.
String? lunationInHouseKey(LunationKind kind, int house) => switch (kind) {
      LunationKind.newMoon => 'lunation_in_house/new/$house',
      LunationKind.fullMoon => 'lunation_in_house/full/$house',
      _ => null,
    };
