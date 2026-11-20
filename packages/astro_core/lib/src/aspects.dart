import 'angles.dart';
import 'model.dart';

enum AspectType {
  conjunction(0),
  sextile(60),
  square(90),
  trine(120),
  opposition(180),

  /// Only used to detect the yod pattern (plan 10.1); never listed in the table.
  quincunx(150);

  final double angle;
  const AspectType(this.angle);

  static const major = [conjunction, sextile, square, trine, opposition];

  AspectQuality get quality => switch (this) {
        conjunction => AspectQuality.conjunction,
        sextile || trine => AspectQuality.harmonious,
        square || opposition => AspectQuality.tense,
        quincunx => AspectQuality.tense,
      };
}

/// Grouping used by content keys like `aspect_point/{point}/{planet}/{quality}`.
enum AspectQuality { conjunction, harmonious, tense }

/// One table of orbs (plan 3.3): aspect × kind of point.
class OrbConfig {
  final Map<AspectType, double> base;

  /// Added when the Sun or the Moon takes part.
  final double luminaryBonus;

  /// Orb for aspects involving ASC, MC or the lunar node.
  final double pointOrb;

  /// Orb for transits (all bodies).
  final double transitOrb;

  const OrbConfig({
    this.base = const {
      AspectType.conjunction: 8,
      AspectType.opposition: 8,
      AspectType.trine: 6,
      AspectType.square: 6,
      AspectType.sextile: 4,
      AspectType.quincunx: 2,
    },
    this.luminaryBonus = 2,
    this.pointOrb = 3,
    this.transitOrb = 1,
  });

  /// "Tight orbs" switch: close to what the old Astromat lists.
  static const tight = OrbConfig(
    base: {
      AspectType.conjunction: 3,
      AspectType.opposition: 3,
      AspectType.trine: 3,
      AspectType.square: 3,
      AspectType.sextile: 3,
      AspectType.quincunx: 2,
    },
    luminaryBonus: 1,
    pointOrb: 3,
  );

  double natalOrb(AspectType t, ChartPoint a, ChartPoint b) {
    if (t == AspectType.quincunx) return base[t]!;
    bool isPoint(ChartPoint p) => p.isAngle || (p.body?.isNode ?? false);
    if (isPoint(a) || isPoint(b)) return pointOrb;
    final lum = (a.body?.isLuminary ?? false) || (b.body?.isLuminary ?? false);
    return base[t]! + (lum ? luminaryBonus : 0);
  }
}

class Aspect {
  final ChartPoint a;
  final ChartPoint b;
  final AspectType type;

  /// Deviation from exact, degrees (always ≥ 0).
  final double orb;

  /// Allowed orb for this pair.
  final double maxOrb;

  /// True when the aspect is getting tighter.
  final bool applying;

  const Aspect(this.a, this.b, this.type, this.orb, this.maxOrb, this.applying);

  /// 1 at exact, 0 at the edge of the orb.
  double get exactness => 1 - orb / maxOrb;

  @override
  String toString() => '$a ${type.name} $b (${orb.toStringAsFixed(2)}°${applying ? ' A' : ' S'})';
}

/// Finds the aspect between two longitudes, if any, within [orbOf].
({AspectType type, double orb, bool applying})? matchAspect(
  double lonA,
  double speedA,
  double lonB,
  double speedB,
  double Function(AspectType) orbOf, {
  Iterable<AspectType> types = AspectType.major,
}) {
  final d = angDiff(lonA, lonB);
  final sep = d.abs();
  ({AspectType type, double orb, bool applying})? best;
  for (final t in types) {
    final dev = sep - t.angle;
    final orb = dev.abs();
    if (orb > orbOf(t)) continue;
    if (best != null && orb >= best.orb) continue;
    final rate = (d >= 0 ? 1 : -1) * (speedA - speedB);
    best = (type: t, orb: orb, applying: dev * rate < 0);
  }
  return best;
}

/// All aspects between [points] (lon, speed) using natal orbs.
List<Aspect> findAspects(
  Map<ChartPoint, ({double lon, double speed})> points,
  OrbConfig config, {
  Iterable<AspectType> types = AspectType.major,
}) {
  final keys = points.keys.toList();
  final out = <Aspect>[];
  for (var i = 0; i < keys.length; i++) {
    for (var j = i + 1; j < keys.length; j++) {
      final a = keys[i], b = keys[j];
      if (a.isAngle && b.isAngle) continue;
      final pa = points[a]!, pb = points[b]!;
      final m = matchAspect(pa.lon, pa.speed, pb.lon, pb.speed, (t) => config.natalOrb(t, a, b), types: types);
      if (m != null) out.add(Aspect(a, b, m.type, m.orb, config.natalOrb(m.type, a, b), m.applying));
    }
  }
  out.sort((x, y) => x.orb.compareTo(y.orb));
  return out;
}
