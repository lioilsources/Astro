import 'aspects.dart';
import 'dignities.dart';
import 'ephemeris.dart';
import 'houses.dart';
import 'model.dart';
import 'time.dart';

enum NodeKind { mean, trueNode }

/// Input of a chart: when and where.
class BirthData {
  final LocalMoment moment;
  final double lat;
  final double lon;
  final String? placeName;
  const BirthData({required this.moment, required this.lat, required this.lon, this.placeName});

  Map<String, Object?> toJson() => {'moment': moment.toJson(), 'lat': lat, 'lon': lon, 'place': placeName};

  factory BirthData.fromJson(Map<String, Object?> j) => BirthData(
        moment: LocalMoment.fromJson((j['moment'] as Map).cast<String, Object?>()),
        lat: (j['lat'] as num).toDouble(),
        lon: (j['lon'] as num).toDouble(),
        placeName: j['place'] as String?,
      );
}

class PlanetState {
  final Body body;
  final Dignity dignity;
  final int score;
  const PlanetState(this.body, this.dignity, this.score);
}

class ChartOptions {
  final HouseSystem? houseSystem;
  final OrbConfig orbs;
  final NodeKind node;
  const ChartOptions({this.houseSystem, this.orbs = const OrbConfig(), this.node = NodeKind.mean});
}

class Chart {
  final BirthData birth;
  final ResolvedTime time;
  final ChartOptions options;
  final Map<Body, EclipticPosition> positions;

  /// Null when the birth time is unknown.
  final HouseResult? houses;
  final HouseDefault houseDefault;
  final List<Aspect> aspects;
  final Map<Body, PlanetState> states;

  /// Bodies that could not be computed for this date (Pluto outside the table).
  final List<Body> missing;

  Chart._(this.birth, this.time, this.options, this.positions, this.houses, this.houseDefault, this.aspects, this.states, this.missing);

  bool get timeKnown => birth.moment.timeKnown;
  Body get nodeBody => options.node == NodeKind.mean ? Body.meanNode : Body.trueNode;

  /// Bodies shown in the table: the ten planets that exist + the chosen node.
  List<Body> get bodies => [...Body.planets.where(positions.containsKey), nodeBody];

  int? houseOf(Body b) {
    final h = houses;
    if (h == null || !h.defined) return null;
    return h.houseOf(positions[b]!.lon);
  }

  double? get asc => houses?.asc;
  double? get mc => houses?.mc;

  /// Longitude of any chart point.
  double? lonOf(ChartPoint p) => p.body != null ? positions[p.body]?.lon : (p.angle == Angle.asc ? asc : mc);

  /// Aspect-capable points with longitude and speed (angles have speed 0 in a natal chart).
  Map<ChartPoint, ({double lon, double speed})> get aspectPoints => {
        for (final b in bodies) ChartPoint.body(b): (lon: positions[b]!.lon, speed: positions[b]!.speed),
        if (houses != null) const ChartPoint.angle(Angle.asc): (lon: houses!.asc, speed: 0),
        if (houses != null) const ChartPoint.angle(Angle.mc): (lon: houses!.mc, speed: 0),
      };

  /// Same moment with a different house system (for the comparison view).
  HouseResult? housesFor(HouseSystem s) {
    if (!timeKnown) return null;
    final h = houses!;
    return housesFromRamc(s, h.ramc, birth.lat, Ephemeris.trueObliquity(time.jdTt));
  }

  static Chart compute(BirthData birth, {ChartOptions options = const ChartOptions()}) {
    final time = resolveMoment(birth.moment, birth.lon);
    final jde = time.jdTt;
    final positions = <Body, EclipticPosition>{};
    final missing = <Body>[];
    for (final b in [...Body.planets, Body.meanNode, Body.trueNode]) {
      if (!Ephemeris.available(b, jde)) {
        missing.add(b);
        continue;
      }
      positions[b] = Ephemeris.positionTT(b, jde);
    }
    final def = defaultHouseSystem(birth.lat);
    HouseResult? houses;
    if (birth.moment.timeKnown) {
      final eps = Ephemeris.trueObliquity(jde);
      final ramc = Ephemeris.apparentSiderealDeg(time.jdUt) + birth.lon;
      houses = housesFromRamc(options.houseSystem ?? def.system, ramc, birth.lat, eps);
    }
    final partial = Chart._(birth, time, options, positions, houses, def, const [], const {}, missing);
    final aspects = findAspects(partial.aspectPoints, options.orbs);
    final states = <Body, PlanetState>{};
    for (final b in Body.planets) {
      final p = positions[b];
      if (p == null) continue;
      final mine = aspects.where((a) => a.a.body == b || a.b.body == b);
      final tense = mine.where((a) => a.type.quality == AspectQuality.tense).length;
      final harm = mine.where((a) => a.type.quality == AspectQuality.harmonious).length;
      states[b] = PlanetState(
        b,
        dignityOf(b, p.sign),
        planetScore(body: b, sign: p.sign, house: partial.houseOf(b), retrograde: p.retrograde, tenseAspects: tense, harmoniousAspects: harm),
      );
    }
    return Chart._(birth, time, options, positions, houses, def, aspects, states, missing);
  }
}
