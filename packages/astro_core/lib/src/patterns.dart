import 'angles.dart';
import 'aspects.dart';
import 'model.dart';

/// Aspect patterns and chart-wide balances (plan 10.1). Only the ten planets
/// take part; the node and the angles are left out.
enum PatternKind {
  grandTrine,
  tSquare,
  grandCross,
  yod,
  kite,
  cradle,
  mysticRectangle,
  modalityExcess,
  modalityLack,
  hemisphere,
  unaspected;

  /// Geometric shapes made of aspects (as opposed to counts).
  bool get isShape => index <= mysticRectangle.index;
}

/// Halves of the chart split by the horizon (above/below) and the meridian (east/west).
enum Hemisphere { above, below, east, west }

class ChartPattern {
  final PatternKind kind;

  /// Planets that form the pattern, in [Body] order.
  final List<Body> bodies;

  /// Apex of a T-square or a yod (more than one when the apex is a conjunction).
  final List<Body> apexes;
  final Element? element;
  final Modality? modality;
  final Hemisphere? hemisphere;

  /// Aspects forming the shape (quincunxes included for a yod); empty for counts.
  final List<Aspect> sides;

  const ChartPattern(
    this.kind,
    this.bodies, {
    this.apexes = const [],
    this.element,
    this.modality,
    this.hemisphere,
    this.sides = const [],
  });

  @override
  String toString() => '${kind.name}${element != null ? '/${element!.name}' : ''}${modality != null ? '/${modality!.name}' : ''}'
      '${hemisphere != null ? '/${hemisphere!.name}' : ''} ${bodies.map((b) => b.name).join(',')}'
      '${apexes.isEmpty ? '' : ' apex ${apexes.map((b) => b.name).join(',')}'}';
}

/// Thresholds for the counts (documented in docs/scoring.md).
const modalityExcessMin = 6;
const modalityLackMax = 1;
const hemisphereMin = 9;

/// Finds patterns among the planets in [lons] (longitude, degrees). [speeds]
/// only affect the applying flag of the returned sides. Hemispheres need
/// [asc] and [mc] (birth time known).
List<ChartPattern> findPatterns(
  Map<Body, double> lons, {
  Map<Body, double> speeds = const {},
  OrbConfig orbs = const OrbConfig(),
  double? asc,
  double? mc,
}) {
  final planets = Body.planets.where(lons.containsKey).toList();
  final points = {
    for (final b in planets) ChartPoint.body(b): (lon: lons[b]!, speed: speeds[b] ?? 0),
  };
  final side = <(Body, Body), Aspect>{};
  for (final a in [...findAspects(points, orbs), ...findAspects(points, orbs, types: const [AspectType.quincunx])]) {
    side[(a.a.body!, a.b.body!)] = a;
    side[(a.b.body!, a.a.body!)] = a;
  }
  AspectType? rel(Body x, Body y) => side[(x, y)]?.type;
  bool has(Body x, Body y, AspectType t) => rel(x, y) == t;
  List<Aspect> sidesOf(List<Body> m) => [
        for (var i = 0; i < m.length; i++)
          for (var j = i + 1; j < m.length; j++)
            if (side[(m[i], m[j])] case final a? when a.type != AspectType.conjunction) a,
      ];

  final raw = <ChartPattern>[];
  final seen = <String>{};
  void add(PatternKind kind, List<Body> members, {List<Body> apexes = const []}) {
    final m = [...members]..sort((a, b) => a.index.compareTo(b.index));
    if (!seen.add('${kind.name}:${m.map((b) => b.index).join(',')}:${apexes.map((b) => b.index).join(',')}')) return;
    raw.add(ChartPattern(kind, m, apexes: apexes, sides: sidesOf(m)));
  }

  final n = planets.length;
  for (var i = 0; i < n; i++) {
    for (var j = i + 1; j < n; j++) {
      final a = planets[i], b = planets[j];
      for (var k = 0; k < n; k++) {
        final c = planets[k];
        if (c == a || c == b) continue;
        // Grand trine: three trines (each triple once).
        if (k > j && has(a, b, AspectType.trine) && has(b, c, AspectType.trine) && has(a, c, AspectType.trine)) {
          add(PatternKind.grandTrine, [a, b, c]);
          for (final d in planets) {
            if (d == a || d == b || d == c) continue;
            for (final (x, y, z) in [(a, b, c), (b, a, c), (c, a, b)]) {
              if (has(d, x, AspectType.opposition) && has(d, y, AspectType.sextile) && has(d, z, AspectType.sextile)) {
                add(PatternKind.kite, [a, b, c, d]);
              }
            }
          }
        }
        // T-square: an opposition and a planet square to both ends.
        if (has(a, b, AspectType.opposition) && has(a, c, AspectType.square) && has(b, c, AspectType.square)) {
          add(PatternKind.tSquare, [a, b, c], apexes: [c]);
        }
        // Yod: a sextile and a planet quincunx to both ends.
        if (has(a, b, AspectType.sextile) && has(a, c, AspectType.quincunx) && has(b, c, AspectType.quincunx)) {
          add(PatternKind.yod, [a, b, c], apexes: [c]);
        }
      }
    }
  }

  // Shapes on two oppositions: grand cross, mystic rectangle, and the cradle on one.
  final opps = [
    for (var i = 0; i < n; i++)
      for (var j = i + 1; j < n; j++)
        if (has(planets[i], planets[j], AspectType.opposition)) (planets[i], planets[j]),
  ];
  for (var i = 0; i < opps.length; i++) {
    final (a, c) = opps[i];
    for (var j = i + 1; j < opps.length; j++) {
      final (b, d) = opps[j];
      if ({a, b, c, d}.length < 4) continue;
      if (has(a, b, AspectType.square) && has(b, c, AspectType.square) && has(c, d, AspectType.square) && has(d, a, AspectType.square)) {
        add(PatternKind.grandCross, [a, b, c, d]);
      }
      for (final (s, t) in [(AspectType.sextile, AspectType.trine), (AspectType.trine, AspectType.sextile)]) {
        // Either b or d may be the neighbour of a on the sextile side.
        for (final (p, q) in [(b, d), (d, b)]) {
          if (has(a, p, s) && has(c, q, s) && has(p, c, t) && has(q, a, t)) add(PatternKind.mysticRectangle, [a, b, c, d]);
        }
      }
    }
    // Cradle: a – b – x – c along three sextiles under the opposition a–c, with trines a–x and b–c.
    for (final b in planets) {
      for (final x in planets) {
        if ({a, b, c, x}.length < 4) continue;
        for (final (e1, e2) in [(a, c), (c, a)]) {
          if (has(e1, b, AspectType.sextile) &&
              has(b, x, AspectType.sextile) &&
              has(x, e2, AspectType.sextile) &&
              has(e1, x, AspectType.trine) &&
              has(b, e2, AspectType.trine)) {
            add(PatternKind.cradle, [a, b, c, x]);
          }
        }
      }
    }
  }

  final shapes = _mergeConjunctions(raw, (x, y) => has(x, y, AspectType.conjunction), sidesOf);
  // A grand cross already contains its four T-squares.
  final crosses = shapes.where((p) => p.kind == PatternKind.grandCross).map((p) => p.bodies.toSet()).toList();
  shapes.removeWhere((p) => p.kind == PatternKind.tSquare && crosses.any((c) => c.containsAll(p.bodies)));

  Sign sign(Body b) => Sign.ofLongitude(lons[b]!);
  final out = <ChartPattern>[
    for (final p in shapes)
      ChartPattern(
        p.kind,
        p.bodies,
        apexes: p.apexes,
        sides: p.sides,
        element: switch (p.kind) {
          PatternKind.grandTrine || PatternKind.kite =>
            _majority(_trineCore(p, shapes).map((b) => sign(b).element), fallback: sign(p.bodies.first).element),
          _ => null,
        },
        modality: switch (p.kind) {
          PatternKind.tSquare || PatternKind.grandCross =>
            _majority(p.bodies.map((b) => sign(b).modality), fallback: sign((p.apexes.isEmpty ? p.bodies : p.apexes).first).modality),
          _ => null,
        },
      ),
  ];

  // Modality balance over all planets.
  final byModality = {for (final m in Modality.values) m: <Body>[]};
  for (final b in planets) {
    byModality[sign(b).modality]!.add(b);
  }
  for (final m in Modality.values) {
    final list = byModality[m]!;
    if (list.length >= modalityExcessMin) out.add(ChartPattern(PatternKind.modalityExcess, list, modality: m));
    if (list.length <= modalityLackMax) out.add(ChartPattern(PatternKind.modalityLack, list, modality: m));
  }

  // Hemispheres: above the horizon = from DSC through MC to ASC; east = from MC through ASC to IC.
  if (asc != null && mc != null) {
    final halves = {for (final h in Hemisphere.values) h: <Body>[]};
    for (final b in planets) {
      halves[norm360(lons[b]! - asc) >= 180 ? Hemisphere.above : Hemisphere.below]!.add(b);
      halves[norm360(lons[b]! - mc) < 180 ? Hemisphere.east : Hemisphere.west]!.add(b);
    }
    for (final h in Hemisphere.values) {
      if (halves[h]!.length >= hemisphereMin) out.add(ChartPattern(PatternKind.hemisphere, halves[h]!, hemisphere: h));
    }
  }

  // Planets without a major aspect to another planet.
  for (final b in planets) {
    final any = planets.any((o) => o != b && side[(b, o)] != null && side[(b, o)]!.type != AspectType.quincunx);
    if (!any) out.add(ChartPattern(PatternKind.unaspected, [b]));
  }
  return out;
}

/// The planets of a kite that make its grand trine (the fourth is opposite one of them).
Iterable<Body> _trineCore(ChartPattern p, List<ChartPattern> shapes) {
  if (p.kind != PatternKind.kite) return p.bodies;
  final gt = shapes.where((g) => g.kind == PatternKind.grandTrine && p.bodies.toSet().containsAll(g.bodies)).firstOrNull;
  return gt?.bodies ?? p.bodies;
}

T _majority<T>(Iterable<T> xs, {required T fallback}) {
  final count = <T, int>{};
  for (final x in xs) {
    count[x] = (count[x] ?? 0) + 1;
  }
  final best = count.values.fold(0, (a, b) => a > b ? a : b);
  final top = count.entries.where((e) => e.value == best).toList();
  return top.length == 1 ? top.single.key : fallback;
}

/// Same shape found twice because one corner is a conjunction → one pattern with both planets.
List<ChartPattern> _mergeConjunctions(
  List<ChartPattern> raw,
  bool Function(Body, Body) conjunct,
  List<Aspect> Function(List<Body>) sidesOf,
) {
  final out = <ChartPattern>[];
  for (final p in raw) {
    final i = out.indexWhere((m) {
      if (m.kind != p.kind) return false;
      final extra = p.bodies.where((b) => !m.bodies.contains(b)).toList();
      if (extra.length > 1) return false;
      if (extra.isEmpty) return true;
      final x = extra.single;
      // The new planet must stand in for one already there.
      return m.bodies.any((b) => conjunct(b, x) && !p.bodies.contains(b));
    });
    if (i < 0) {
      out.add(p);
      continue;
    }
    final m = out[i];
    final bodies = {...m.bodies, ...p.bodies}.toList()..sort((a, b) => a.index.compareTo(b.index));
    final apexes = {...m.apexes, ...p.apexes}.toList()..sort((a, b) => a.index.compareTo(b.index));
    out[i] = ChartPattern(m.kind, bodies, apexes: apexes, sides: sidesOf(bodies));
  }
  return out;
}
