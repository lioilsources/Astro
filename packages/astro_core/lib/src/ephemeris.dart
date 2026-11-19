import 'dart:math' as math;

import 'package:astronomia/apparent.dart' as apparent;
import 'package:astronomia/moonposition.dart' as moon;
import 'package:astronomia/nutation.dart' as nut;
import 'package:astronomia/planetposition.dart';
import 'package:astronomia/precess.dart';
import 'package:astronomia/pluto.dart' as meeus_pluto;
import 'package:astronomia/sidereal.dart' as sidereal;

import 'angles.dart';
import 'model.dart';
import 'pluto_table.dart' as pluto_table;
import 'time.dart';

/// Thrown when a body cannot be computed for the requested date
/// (Pluto outside the precomputed table and the Meeus series range).
class EphemerisRangeError implements Exception {
  final Body body;
  final double jde;
  EphemerisRangeError(this.body, this.jde);
  @override
  String toString() => 'No ephemeris for ${body.name} at JDE $jde';
}

/// Apparent geocentric ecliptic positions of date (tropical zodiac).
///
/// Planets: VSOP87B (J2000) + light time + precession to date + aberration
/// + nutation. Moon: Meeus ch. 47. Pluto: table from JPL DE440, Meeus ch. 37
/// as a fallback for 1885–2099. See docs/ephemeris.md.
class Ephemeris {
  Ephemeris._();

  static final Map<int, Planet> _vsop = {};
  static Planet _planet(int id) => _vsop.putIfAbsent(id, () => Planet(id));

  static const _vsopId = {
    Body.mercury: planetMercury,
    Body.venus: planetVenus,
    Body.mars: planetMars,
    Body.jupiter: planetJupiter,
    Body.saturn: planetSaturn,
    Body.uranus: planetUranus,
    Body.neptune: planetNeptune,
  };

  /// Whether [body] can be computed at [jde].
  static bool available(Body body, double jde) {
    if (body != Body.pluto) return true;
    return pluto_table.covers(jde) || _meeusPlutoRange(jde);
  }

  static bool _meeusPlutoRange(double jde) => jde >= 2408816.5 && jde < 2488069.5; // 1885–2099

  /// Longitude and latitude (degrees) at Terrestrial Time [jde].
  static ({double lon, double lat, double dist}) lonLatTT(Body body, double jde) {
    switch (body) {
      case Body.moon:
        final m = moon.position(jde);
        final n = nut.nutation(jde);
        return (lon: norm360((m.lon + n.dPsi) / deg), lat: m.lat / deg, dist: m.delta / 149597870.7);
      case Body.meanNode:
        return (lon: norm360(moon.node(jde) / deg), lat: 0, dist: 0);
      case Body.trueNode:
        return (lon: _osculatingNode(jde), lat: 0, dist: 0);
      default:
        return _planetary(body, jde);
    }
  }

  /// True (osculating) node: the ascending node of the instantaneous lunar orbit,
  /// from the Moon's position and velocity (Meeus ch. 47 positions).
  static double _osculatingNode(double jde) {
    const dt = 0.01;
    ({double x, double y, double z}) at(double t) {
      final m = moon.position(t);
      final n = nut.nutation(t);
      return _rect(m.lon + n.dPsi, m.lat, m.delta);
    }

    final p = at(jde), a = at(jde - dt), b = at(jde + dt);
    final vx = (b.x - a.x) / (2 * dt), vy = (b.y - a.y) / (2 * dt), vz = (b.z - a.z) / (2 * dt);
    final hx = p.y * vz - p.z * vy;
    final hy = p.z * vx - p.x * vz;
    return norm360(math.atan2(hx, -hy) / deg);
  }

  static ({double x, double y, double z}) _rect(double lon, double lat, double r) =>
      (x: r * math.cos(lat) * math.cos(lon), y: r * math.cos(lat) * math.sin(lon), z: r * math.sin(lat));

  /// Heliocentric J2000 ecliptic rectangular coordinates, AU.
  static ({double x, double y, double z}) _helio(Body body, double jde) {
    if (body == Body.pluto) {
      final t = pluto_table.heliocentric(jde);
      if (t != null) return t;
      if (!_meeusPlutoRange(jde)) throw EphemerisRangeError(body, jde);
      final p = meeus_pluto.heliocentric(jde);
      return _rect(p.lon, p.lat, p.r);
    }
    final p = _planet(_vsopId[body]!).position2000(jde);
    return _rect(p.lon, p.lat, p.range);
  }

  static ({double lon, double lat, double dist}) _planetary(Body body, double jde) {
    final e2000 = _planet(planetEarth).position2000(jde);
    final e = _rect(e2000.lon, e2000.lat, e2000.range);
    double x, y, z;
    if (body == Body.sun) {
      x = -e.x;
      y = -e.y;
      z = -e.z;
    } else {
      var p = _helio(body, jde);
      x = p.x - e.x;
      y = p.y - e.y;
      z = p.z - e.z;
      final tau = 0.0057755183 * math.sqrt(x * x + y * y + z * z);
      p = _helio(body, jde - tau);
      x = p.x - e.x;
      y = p.y - e.y;
      z = p.z - e.z;
    }
    final dist = math.sqrt(x * x + y * y + z * z);
    var lon = math.atan2(y, x);
    var lat = math.atan2(z, math.sqrt(x * x + y * y));
    final year = 2000 + (jde - 2451545.0) / 365.25;
    final prec = EclipticPrecessor(2000, year).precess(lon, lat);
    lon = prec.lon;
    lat = prec.lat;
    final ab = apparent.eclipticAberration(lon, lat, jde);
    lon += ab.dLon;
    lat += ab.dLat;
    lon += nut.nutation(jde).dPsi;
    return (lon: norm360(lon / deg), lat: lat / deg, dist: dist);
  }

  /// Full position with daily motion, at Universal Time [jdUt].
  static EclipticPosition position(Body body, double jdUt) {
    final jde = jdUt + deltaTSeconds(decimalYearOfJd(jdUt)) / 86400;
    return positionTT(body, jde);
  }

  static EclipticPosition positionTT(Body body, double jde) {
    final now = lonLatTT(body, jde);
    const h = 0.25;
    final a = lonLatTT(body, jde - h).lon;
    final b = lonLatTT(body, jde + h).lon;
    return EclipticPosition(lon: now.lon, lat: now.lat, speed: angDiff(b, a) / (2 * h), distance: now.dist);
  }

  /// Longitude only (cheaper), at Universal Time.
  static double longitude(Body body, double jdUt) =>
      lonLatTT(body, jdUt + deltaTSeconds(decimalYearOfJd(jdUt)) / 86400).lon;

  /// True obliquity of the ecliptic, degrees.
  static double trueObliquity(double jde) => (nut.meanObliquity(jde) + nut.nutation(jde).dEps) / deg;

  /// Apparent Greenwich sidereal time in degrees.
  static double apparentSiderealDeg(double jdUt) => norm360(sidereal.apparent(jdUt) / 240);
}
