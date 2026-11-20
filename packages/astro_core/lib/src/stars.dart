import 'dart:math' as math;

import 'package:astronomia/apparent.dart' as apparent;
import 'package:astronomia/coord.dart' as coord;
import 'package:astronomia/nutation.dart' as nut;
import 'package:astronomia/precess.dart' as precess;

import 'angles.dart';
import 'model.dart';
import 'star_catalog.dart';

/// Orb of a star conjunction in ecliptic longitude (owner decision 18).
const double starOrb = 1.0;

/// One of the 32 fixed stars of plan 10.6, J2000 catalogue data.
class FixedStar {
  /// Content id (`star/{id}`).
  final String id;

  /// Hipparcos number; null for Praesepe (a cluster).
  final int? hip;
  final double ra2000;
  final double dec2000;

  /// Proper motion in mas/yr; [pmRa] is μα·cos δ as in the catalogue.
  final double pmRa;
  final double pmDec;
  final double vmag;
  const FixedStar(this.id, this.hip, this.ra2000, this.dec2000, this.pmRa, this.pmDec, this.vmag);

  /// The four royal stars of Persian tradition.
  bool get royal => const {'aldebaran', 'regulus', 'antares', 'fomalhaut'}.contains(id);

  /// Apparent ecliptic longitude and latitude of date (degrees) at Terrestrial Time [jde]:
  /// proper motion + precession (Meeus ch. 21), mean obliquity, aberration, nutation.
  ({double lon, double lat}) positionTT(double jde) {
    const mas = deg / 3600000;
    final epoch = 2000 + (jde - 2451545.0) / 365.25;
    final dec0 = dec2000 * deg;
    final eq = precess.position(ra2000 * deg, dec0, 2000, epoch, pmRa * mas / math.cos(dec0), pmDec * mas);
    final eps = nut.meanObliquity(jde);
    final ecl = coord.eqToEcl(eq.ra, eq.dec, math.sin(eps), math.cos(eps));
    final ab = apparent.eclipticAberration(ecl.lon, ecl.lat, jde);
    final lon = ecl.lon + ab.dLon + nut.nutation(jde).dPsi;
    return (lon: norm360(lon / deg), lat: (ecl.lat + ab.dLat) / deg);
  }

  double longitudeTT(double jde) => positionTT(jde).lon;
}

final List<FixedStar> fixedStars = [for (final r in starRows) FixedStar(r.$1, r.$2, r.$3, r.$4, r.$5, r.$6, r.$7)];

/// Content ids of the stars in plan order.
final List<String> starIds = [for (final s in fixedStars) s.id];

/// Points a star conjunction is counted with: Sun–Pluto, ASC, MC.
const List<String> starTargetIds = [
  'sun', 'moon', 'mercury', 'venus', 'mars', 'jupiter', 'saturn', 'uranus', 'neptune', 'pluto', 'asc', 'mc',
];

/// A conjunction of a chart point with a fixed star.
class StarContact {
  final FixedStar star;
  final ChartPoint point;

  /// Longitude of the star of date.
  final double starLon;

  /// Unsigned distance in longitude, degrees (≤ [starOrb]).
  final double orb;
  const StarContact(this.star, this.point, this.starLon, this.orb);
  @override
  String toString() => '${star.id}–${point.id} ${orb.toStringAsFixed(2)}°';
}

/// Longitudes of all stars at [jde], keyed by star.
Map<FixedStar, double> starLongitudes(double jde) => {for (final s in fixedStars) s: s.longitudeTT(jde)};

/// Conjunctions by ecliptic longitude only (latitude ignored, as tradition does).
/// [points] maps chart points to longitudes; only planets Sun–Pluto and ASC/MC count.
/// Sorted by orb, tightest first.
List<StarContact> findStarContacts(Map<ChartPoint, double> points, Map<FixedStar, double> starLons, {double orb = starOrb}) {
  final out = <StarContact>[];
  points.forEach((p, lon) {
    if (!(p.isAngle || (p.body?.isPlanet ?? false))) return;
    starLons.forEach((s, sl) {
      final d = angDist(lon, sl);
      if (d <= orb) out.add(StarContact(s, p, sl, d));
    });
  });
  out.sort((a, b) => a.orb.compareTo(b.orb));
  return out;
}
