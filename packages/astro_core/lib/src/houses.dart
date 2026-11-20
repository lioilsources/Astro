import 'dart:math' as math;

import 'angles.dart';

enum HouseSystem {
  placidus,
  koch,
  regiomontanus,
  campanus,
  porphyry,
  equal,
  wholeSign,
  meridian,
  morinus;

  /// Systems undefined beyond the polar circle (|lat| > 90° − ε).
  bool get polarSensitive => this == placidus || this == koch;
}

/// Default system by birth latitude (plan 3.3). Longitude plays no role.
class HouseDefault {
  final HouseSystem system;

  /// Placidus between 60° and 66°: houses get very unequal, suggest Porphyry.
  final bool warnUnequal;
  const HouseDefault(this.system, {this.warnUnequal = false});
}

HouseDefault defaultHouseSystem(double latDeg) {
  final a = latDeg.abs();
  if (a <= 60) return const HouseDefault(HouseSystem.placidus);
  if (a <= 66) return const HouseDefault(HouseSystem.placidus, warnUnequal: true);
  return const HouseDefault(HouseSystem.porphyry);
}

class HouseResult {
  final HouseSystem system;

  /// Cusps 1..12 in degrees (index 0 = cusp 1). Null when the system is undefined here.
  final List<double>? cusps;
  final double asc;
  final double mc;
  final double ramc;
  const HouseResult(this.system, this.cusps, this.asc, this.mc, this.ramc);

  bool get defined => cusps != null;

  /// House 1..12 containing ecliptic longitude [lon].
  int houseOf(double lon) {
    final c = cusps!;
    for (var i = 0; i < 12; i++) {
      final start = c[i];
      final end = c[(i + 1) % 12];
      final span = norm360(end - start);
      if (norm360(lon - start) < span) return i + 1;
    }
    return 12;
  }

  /// Size of each house in degrees.
  List<double> get sizes => [for (var i = 0; i < 12; i++) norm360(cusps![(i + 1) % 12] - cusps![i])];
}

/// Ecliptic longitude of the ascendant for sidereal angle [ramc] and pole [poleRad]
/// (the true ascendant uses the geographic latitude as pole). Radians in, degrees out.
double _ascOf(double ramc, double poleRad, double eps) =>
    norm360(math.atan2(math.cos(ramc), -(math.sin(ramc) * math.cos(eps) + math.tan(poleRad) * math.sin(eps))) / deg);

double _eclOfRa(double ra, double eps) => norm360(math.atan2(math.sin(ra), math.cos(ra) * math.cos(eps)) / deg);

/// Computes house cusps from RAMC (degrees), geographic latitude (degrees)
/// and true obliquity (degrees). Independent of time so it can be tested
/// against reference implementations with identical inputs.
HouseResult housesFromRamc(HouseSystem system, double ramcDeg, double latDeg, double epsDeg) {
  final th = ramcDeg * deg;
  final phi = latDeg * deg;
  final eps = epsDeg * deg;
  final mc = _eclOfRa(th, eps);
  var asc = _ascOf(th, phi, eps);
  // Inside the polar circle the formula can return the western intersection;
  // keep the ascendant within 180° after the MC (Swiss Ephemeris convention).
  if (norm360(asc - mc) > 180) asc = norm360(asc + 180);
  final polar = latDeg.abs() >= 90 - epsDeg;

  List<double>? c;
  // Intermediate cusps lie within 180° after the MC; inside the polar circle the
  // pole-based formulas may return the opposite point.
  double q(double c) => norm360(c - mc) > 180 ? norm360(c + 180) : c;
  List<double> fromQuadrants(double a11, double a12, double a2, double a3) {
    final c11 = q(a11), c12 = q(a12), c2 = q(a2), c3 = q(a3);
    return [asc, c2, c3, norm360(mc + 180), norm360(c11 + 180), norm360(c12 + 180), norm360(asc + 180), norm360(c2 + 180), norm360(c3 + 180), mc, c11, c12];
  }

  switch (system) {
    case HouseSystem.placidus:
      if (polar) break;
      double cusp(double Function(double ad) raOf) {
        var ad = 0.0;
        var lam = 0.0;
        for (var i = 0; i < 60; i++) {
          lam = _eclOfRa(raOf(ad), eps) * deg;
          final dec = math.asin(math.sin(eps) * math.sin(lam));
          final x = math.tan(phi) * math.tan(dec);
          if (x.abs() > 1) return double.nan;
          final next = math.asin(x);
          if ((next - ad).abs() < 1e-12) {
            ad = next;
            break;
          }
          ad = next;
        }
        return _eclOfRa(raOf(ad), eps);
      }
      final c11 = cusp((ad) => th + (math.pi / 2 + ad) / 3);
      final c12 = cusp((ad) => th + 2 * (math.pi / 2 + ad) / 3);
      final c2 = cusp((ad) => th + math.pi - 2 * (math.pi / 2 - ad) / 3);
      final c3 = cusp((ad) => th + math.pi - (math.pi / 2 - ad) / 3);
      if ([c11, c12, c2, c3].any((v) => v.isNaN)) break;
      c = fromQuadrants(c11, c12, c2, c3);
    case HouseSystem.koch:
      if (polar) break;
      final decMc = math.asin(math.sin(eps) * math.sin(mc * deg));
      final ad3 = math.asin(math.tan(phi) * math.tan(decMc)) / 3;
      final d30 = 30 * deg;
      c = fromQuadrants(
        _ascOf(th + d30 - 2 * ad3 - math.pi / 2, phi, eps),
        _ascOf(th + 2 * d30 - ad3 - math.pi / 2, phi, eps),
        _ascOf(th + 4 * d30 + ad3 - math.pi / 2, phi, eps),
        _ascOf(th + 5 * d30 + 2 * ad3 - math.pi / 2, phi, eps),
      );
    case HouseSystem.regiomontanus:
      final p1 = math.atan(math.tan(phi) * 0.5);
      final p2 = math.atan(math.tan(phi) * math.sqrt(3) / 2);
      c = fromQuadrants(
        _ascOf(th - 60 * deg, p1, eps),
        _ascOf(th - 30 * deg, p2, eps),
        _ascOf(th + 30 * deg, p2, eps),
        _ascOf(th + 60 * deg, p1, eps),
      );
    case HouseSystem.campanus:
      final p1 = math.asin(math.sin(phi) / 2);
      final p2 = math.asin(math.sqrt(3) / 2 * math.sin(phi));
      final x1 = math.atan(math.sqrt(3) / math.cos(phi));
      final x2 = math.atan(1 / math.sqrt(3) / math.cos(phi));
      c = fromQuadrants(
        _ascOf(th - math.pi / 2 + (math.pi / 2 - x1), p1, eps),
        _ascOf(th - math.pi / 2 + (math.pi / 2 - x2), p2, eps),
        _ascOf(th + x2, p2, eps),
        _ascOf(th + x1, p1, eps),
      );
    case HouseSystem.porphyry:
      final q1 = norm360(asc - mc);
      final q2 = norm360(mc + 180 - asc);
      c = fromQuadrants(norm360(mc + q1 / 3), norm360(mc + 2 * q1 / 3), norm360(asc + q2 / 3), norm360(asc + 2 * q2 / 3));
    case HouseSystem.equal:
      c = [for (var i = 0; i < 12; i++) norm360(asc + 30 * i)];
    case HouseSystem.wholeSign:
      final start = (asc ~/ 30) * 30.0;
      c = [for (var i = 0; i < 12; i++) norm360(start + 30 * i)];
    case HouseSystem.meridian:
      c = [for (var n = 1; n <= 12; n++) _eclOfRa(th + (n - 10) * 30 * deg, eps)];
    case HouseSystem.morinus:
      c = [
        for (var n = 1; n <= 12; n++)
          () {
            final a = th + (n - 10) * 30 * deg;
            return norm360(math.atan2(math.sin(a) * math.cos(eps), math.cos(a)) / deg);
          }()
      ];
  }
  return HouseResult(system, c, asc, mc, norm360(ramcDeg));
}
