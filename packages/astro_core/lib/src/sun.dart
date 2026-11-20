import 'dart:math' as math;

import 'package:astronomia/coord.dart' as coord;
import 'package:astronomia/sidereal.dart' as sidereal;
import 'package:astronomia/solar.dart' as solar;

import 'angles.dart';
import 'time.dart';

/// The Sun's upper limb touching the horizon: refraction 34′ + semidiameter 16′
/// below the geometric horizon (the convention of almanacs and of skyfield).
const sunriseAltitudeDeg = -50 / 60;

/// Sunrise or sunset.
class SunCrossing {
  /// Julian Day UT.
  final double jd;

  /// True = sunrise, false = sunset.
  final bool rising;
  const SunCrossing(this.jd, this.rising);
  @override
  String toString() => '${rising ? 'rise' : 'set'} $jd';
}

/// Sunrise and sunset from the `astronomia` solar position (Meeus ch. 25,
/// apparent, ~0.01°) and apparent sidereal time. See docs/ephemeris.md.
class SunRiseSet {
  SunRiseSet._();

  /// Apparent altitude of the Sun's centre without refraction, degrees.
  /// [lon] is east positive.
  static double altitude(double jdUt, double lat, double lon) {
    final jde = jdUt + deltaTSeconds(decimalYearOfJd(jdUt)) / 86400;
    final eq = solar.apparentEquatorial(jde);
    final st = sidereal.apparent(jdUt) / 86400 * 2 * math.pi;
    return coord.eqToHz(eq.ra, eq.dec, lat * deg, -lon * deg, st).alt / deg;
  }

  /// All sunrises and sunsets in [from, to) (Julian Days UT), in time order.
  /// Sampled every [step] days, then bisected to well under a second.
  static List<SunCrossing> crossings(double from, double to, double lat, double lon, {double step = 5 / 1440}) {
    double f(double t) => altitude(t, lat, lon) - sunriseAltitudeDeg;
    final out = <SunCrossing>[];
    var t0 = from;
    var f0 = f(t0);
    while (t0 < to) {
      final t1 = math.min(t0 + step, to);
      final f1 = f(t1);
      if ((f0 <= 0 && f1 > 0) || (f0 > 0 && f1 <= 0)) {
        var a = t0, b = t1;
        final fa = f0;
        for (var i = 0; i < 24; i++) {
          final m = (a + b) / 2;
          if ((f(m) > 0) == (fa > 0)) {
            a = m;
          } else {
            b = m;
          }
        }
        out.add(SunCrossing((a + b) / 2, f1 > 0));
      }
      t0 = t1;
      f0 = f1;
    }
    return out;
  }

  /// UT of local mean midnight that starts the civil date at longitude [lon].
  static double localMidnight(int year, int month, int day, double lon) => julianDay(year, month, day, 0) - lon / 360;

  /// Sunrise and sunset of a local date (the local mean solar day at [lon]);
  /// a null part when the Sun does not rise or set that day (polar day or night).
  static ({double? rise, double? set}) of(int year, int month, int day, double lat, double lon) {
    final m = localMidnight(year, month, day, lon);
    final c = crossings(m, m + 1, lat, lon);
    return (
      rise: c.where((x) => x.rising).firstOrNull?.jd,
      set: c.where((x) => !x.rising).firstOrNull?.jd,
    );
  }
}
