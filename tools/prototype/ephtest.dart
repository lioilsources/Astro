// Feasibility prototype for PLAN-astro-app.md (not production code).
// Depends on: astronomia 1.1.1 (MIT, pure Dart). Run: dart create -t console x && dart pub add astronomia:1.1.1
// Compares a neutral sample chart (2000-01-01 12:00 UT, Prague) with reference values.
// Optional CLI chart: dart run ephtest.dart <y> <m> <d> <h> <min> <lat> <lon> <deltaT_sec>

import 'dart:math' as math;
import 'package:astronomia/julian.dart';
import 'package:astronomia/planetposition.dart';
import 'package:astronomia/elliptic.dart' as elliptic;
import 'package:astronomia/moonposition.dart' as moon;
import 'package:astronomia/pluto.dart' as pluto;
import 'package:astronomia/sidereal.dart' as sidereal;
import 'package:astronomia/nutation.dart' as nut;
import 'package:astronomia/coord.dart';
import 'package:astronomia/precess.dart';

const rad = math.pi / 180;
double norm(double d) => (d % 360 + 360) % 360;
String dms(double d) {
  d = norm(d);
  const signs = ['Ari','Tau','Gem','Cnc','Leo','Vir','Lib','Sco','Sgr','Cap','Aqr','Psc'];
  final s = (d ~/ 30); final r = d - s * 30; final m = ((r - r.floor()) * 60);
  return '${r.floor().toString().padLeft(2)}°${m.floor().toString().padLeft(2, '0')}\' ${signs[s]} (${d.toStringAsFixed(3)})';
}

Map<String, double> chart(double jdUt, double deltaTsec, double latDeg, double lonDeg) {
  final jde = jdUt + deltaTsec / 86400;
  final earth = Planet(planetEarth);
  final n = nut.nutation(jde);
  final eps = nut.meanObliquity(jde) + n.dEps;
  final out = <String, double>{};
  // Sun: geocentric = Earth heliocentric + 180, FK5/aberration approx
  final pe = earth.position(jde);
  out['Sun'] = norm((pe.lon + math.pi + n.dPsi) / rad - 20.4898 / 3600 / pe.range);
  final m = moon.position(jde);
  out['Moon'] = norm((m.lon + n.dPsi) / rad);
  const ids = {'Mercury': planetMercury, 'Venus': planetVenus, 'Mars': planetMars, 'Jupiter': planetJupiter, 'Saturn': planetSaturn, 'Uranus': planetUranus, 'Neptune': planetNeptune};
  ids.forEach((name, id) {
    final eq = elliptic.position(Planet(id), earth, jde);
    final ecl = eqToEcl(eq.ra, eq.dec, math.sin(eps), math.cos(eps));
    out[name] = norm(ecl.lon / rad);
  });
  // Pluto: heliocentric J2000 -> geocentric J2000 -> precess to date
  final e0 = earth.position2000(jde);
  double ex = e0.range * math.cos(e0.lat) * math.cos(e0.lon), ey = e0.range * math.cos(e0.lat) * math.sin(e0.lon), ez = e0.range * math.sin(e0.lat);
  var tau = 0.0; late double x, y, z;
  for (var i = 0; i < 2; i++) {
    final p = pluto.heliocentric(jde - tau);
    x = p.r * math.cos(p.lat) * math.cos(p.lon) - ex; y = p.r * math.cos(p.lat) * math.sin(p.lon) - ey; z = p.r * math.sin(p.lat) - ez;
    tau = 0.0057755183 * math.sqrt(x * x + y * y + z * z);
  }
  final pl = EclipticPrecessor(2000.0, jdeToJulianYear(jde)).precess(math.atan2(y, x), math.atan2(z, math.sqrt(x * x + y * y)));
  out['Pluto'] = norm((pl.lon + n.dPsi) / rad);
  out['Node(mean)'] = norm(moon.node(jde) / rad);
  out['Node(true)'] = norm(moon.trueNode(jde) / rad);
  // Angles and Placidus
  final ramc = norm(sidereal.apparent(jdUt) / 240 + lonDeg) * rad;
  final phi = latDeg * rad;
  double eclOfRa(double ra) => math.atan2(math.sin(ra), math.cos(ra) * math.cos(eps));
  out['MC'] = norm(eclOfRa(ramc) / rad);
  out['ASC'] = norm(math.atan2(math.cos(ramc), -(math.sin(ramc) * math.cos(eps) + math.tan(phi) * math.sin(eps))) / rad);
  double cusp(double Function(double ad) raOf) {
    var ad = 0.0; var lam = 0.0;
    for (var i = 0; i < 50; i++) {
      lam = eclOfRa(raOf(ad));
      final dec = math.asin(math.sin(eps) * math.sin(lam));
      ad = math.asin(math.tan(phi) * math.tan(dec));
    }
    return norm(lam / rad);
  }
  out['H11'] = cusp((ad) => ramc + (math.pi / 2 + ad) / 3);
  out['H12'] = cusp((ad) => ramc + 2 * (math.pi / 2 + ad) / 3);
  out['H2'] = cusp((ad) => ramc + math.pi - 2 * (math.pi / 2 - ad) / 3);
  out['H3'] = cusp((ad) => ramc + math.pi - (math.pi / 2 - ad) / 3);
  return out;
}

void report(String title, Map<String, double> got, Map<String, double> ref) {
  print('== $title');
  var worst = 0.0;
  got.forEach((k, v) {
    final r = ref[k];
    var line = '${k.padRight(11)} ${dms(v)}';
    if (r != null) { var d = (v - r + 540) % 360 - 180; worst = math.max(worst, d.abs()); line += '   ref ${r.toStringAsFixed(3)}  diff ${(d * 60).toStringAsFixed(2)}\''; }
    print(line);
  });
  print('worst abs diff: ${(worst * 60).toStringAsFixed(2)} arcmin');
}

void main(List<String> args) {
  // Neutral sample: 2000-01-01 12:00 UT, Praha 50°05'N 14°25'E, reference = Astromat chart.php parameters
  final a = chart(calendarGregorianToJD(2000, 1, 1.5), 63.8, 50 + 5 / 60, 14 + 25 / 60);
  report('J2000 Praha vs Astromat', a, {
    'Sun': 280.377, 'Moon': 223.317, 'Mercury': 271.904, 'Venus': 241.575, 'Mars': 327.978, 'Jupiter': 25.263, 'Saturn': 40.393,
    'Uranus': 314.818, 'Neptune': 303.219, 'Pluto': 251.38, 'Node(mean)': 125.043, 'ASC': 49.69, 'H2': 76.087, 'H3': 94.804,
    'MC': 293.047, 'H11': 315.672, 'H12': 351.49,
  });
  if (args.length == 8) {
    // local-only chart from CLI: y m d h min lat lon deltaT
    final v = args.map(double.parse).toList();
    final b = chart(calendarGregorianToJD(v[0].toInt(), v[1].toInt(), v[2] + (v[3] + v[4] / 60) / 24), v[7], v[5], v[6]);
    report('CLI chart', b, {});
  }
}
