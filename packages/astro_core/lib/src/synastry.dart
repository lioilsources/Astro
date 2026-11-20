import 'angles.dart';
import 'aspects.dart';
import 'chart.dart';
import 'model.dart';

/// Kind of relationship between the two people (plan 10.4). Only [partner]
/// shows the optional `partner` layer of a text (attraction and intimacy).
enum Relationship {
  partner,
  parentChild,
  siblings,
  friends,
  colleagues;

  /// The single gate for the `partner` layer: never for parent and child.
  bool get showsPartnerLayer => this == partner;
}

/// Largest difference of every planet for two charts to count as near-identical.
const twinsMaxPlanetDiff = 1.0;

/// A planet of one person in a house of the other.
class HouseOverlay {
  final Body body;

  /// House (1..12) of the host chart.
  final int house;

  /// True when the planet belongs to the first person (and the house to the second).
  final bool ofFirst;
  const HouseOverlay(this.body, this.house, {required this.ofFirst});

  @override
  String toString() => '${ofFirst ? 'A' : 'B'}:${body.name} in ${ofFirst ? 'B' : 'A'}:$house';
}

/// What differs between two near-identical charts (twins).
class TwinsDiff {
  /// Largest planet difference, degrees (below [twinsMaxPlanetDiff]).
  final double maxPlanetDiff;

  /// Birth moments apart, minutes (absolute).
  final double minutesApart;

  /// Second minus first, signed degrees; null without birth times.
  final double? ascDiff;
  final double? mcDiff;

  /// Cusp 1..12 differences (second minus first); null without houses in either chart.
  final List<double>? cuspDiffs;

  /// Planets whose own house differs: body → (house of the first, house of the second).
  final Map<Body, (int, int)> houseChanges;

  const TwinsDiff({
    required this.maxPlanetDiff,
    required this.minutesApart,
    this.ascDiff,
    this.mcDiff,
    this.cuspDiffs,
    this.houseChanges = const {},
  });
}

/// Comparison of two charts (plan 10.4): inter-chart aspects and house overlays.
class Synastry {
  final Chart first;
  final Chart second;

  /// Aspects between the charts. [Aspect.a] is always a point of [first],
  /// [Aspect.b] a point of [second]; angle–angle pairs are left out.
  /// `applying` has no meaning between two natal charts and is always false.
  final List<Aspect> aspects;

  /// Planets of each person in the houses of the other (only where the host has houses).
  final List<HouseOverlay> overlays;

  /// Non-null when every planet is less than 1° apart (twins).
  final TwinsDiff? twins;

  const Synastry._(this.first, this.second, this.aspects, this.overlays, this.twins);

  static Synastry compute(Chart first, Chart second, {OrbConfig? orbs}) {
    final config = orbs ?? first.options.orbs;
    final aspects = synastryAspects(_points(first), _points(second), config);
    final overlays = <HouseOverlay>[
      for (final b in Body.planets)
        if (first.positions[b] != null && _houseIn(second, first.positions[b]!.lon) != null)
          HouseOverlay(b, _houseIn(second, first.positions[b]!.lon)!, ofFirst: true),
      for (final b in Body.planets)
        if (second.positions[b] != null && _houseIn(first, second.positions[b]!.lon) != null)
          HouseOverlay(b, _houseIn(first, second.positions[b]!.lon)!, ofFirst: false),
    ];
    return Synastry._(first, second, aspects, overlays, twinsDiff(first, second));
  }

  /// Aspects of one person's planets to the other person's planets only.
  List<Aspect> get planetAspects => [for (final a in aspects) if (!a.a.isAngle && !a.b.isAngle) a];

  /// Aspects of one person's planets to the other person's ASC or MC.
  List<Aspect> get pointAspects => [for (final a in aspects) if (a.a.isAngle || a.b.isAngle) a];

  static Map<ChartPoint, double> _points(Chart c) => {
        for (final b in Body.planets)
          if (c.positions[b] != null) ChartPoint.body(b): c.positions[b]!.lon,
        if (c.houses != null) const ChartPoint.angle(Angle.asc): c.houses!.asc,
        if (c.houses != null) const ChartPoint.angle(Angle.mc): c.houses!.mc,
      };

  static int? _houseIn(Chart host, double lon) {
    final h = host.houses;
    if (h == null || !h.defined) return null;
    return h.houseOf(lon);
  }
}

/// Inter-chart aspects with natal orbs (plan 3.3): every point of [first]
/// against every point of [second], except angle–angle. Sorted by orb.
List<Aspect> synastryAspects(Map<ChartPoint, double> first, Map<ChartPoint, double> second, OrbConfig config) {
  final out = <Aspect>[];
  for (final MapEntry(key: a, value: la) in first.entries) {
    for (final MapEntry(key: b, value: lb) in second.entries) {
      if (a.isAngle && b.isAngle) continue;
      final m = matchAspect(la, 0, lb, 0, (t) => config.natalOrb(t, a, b));
      if (m != null) out.add(Aspect(a, b, m.type, m.orb, config.natalOrb(m.type, a, b), false));
    }
  }
  out.sort((x, y) => x.orb.compareTo(y.orb));
  return out;
}

/// Near-identical charts (plan 10.4): all ten planets less than 1° apart.
/// Returns what still differs (axes, cusps, houses of the planets), or null.
TwinsDiff? twinsDiff(Chart first, Chart second) {
  var maxDiff = 0.0;
  for (final b in Body.planets) {
    final pa = first.positions[b], pb = second.positions[b];
    if (pa == null || pb == null) return null;
    final d = angDist(pa.lon, pb.lon);
    if (d >= twinsMaxPlanetDiff) return null;
    if (d > maxDiff) maxDiff = d;
  }
  final ha = first.houses, hb = second.houses;
  final both = ha != null && hb != null;
  final cusps = both && ha.defined && hb.defined;
  return TwinsDiff(
    maxPlanetDiff: maxDiff,
    minutesApart: (second.time.jdUt - first.time.jdUt).abs() * 1440,
    ascDiff: both ? angDiff(hb.asc, ha.asc) : null,
    mcDiff: both ? angDiff(hb.mc, ha.mc) : null,
    cuspDiffs: cusps ? [for (var i = 0; i < 12; i++) angDiff(hb.cusps![i], ha.cusps![i])] : null,
    houseChanges: cusps
        ? {
            for (final b in Body.planets)
              if (first.houseOf(b) != second.houseOf(b)) b: (first.houseOf(b)!, second.houseOf(b)!),
          }
        : const {},
  );
}
