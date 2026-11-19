import 'dart:math' as math;

const double deg = math.pi / 180;

/// Normalizes degrees to [0, 360).
double norm360(double d) {
  final r = d % 360;
  return r < 0 ? r + 360 : r;
}

/// Signed shortest difference a - b in degrees, in (-180, 180].
double angDiff(double a, double b) {
  var d = norm360(a - b);
  if (d > 180) d -= 360;
  return d;
}

/// Shortest unsigned distance between two longitudes, 0..180.
double angDist(double a, double b) => angDiff(a, b).abs();

/// Formats a longitude within its sign, e.g. 22°21′.
String formatInSign(double lon) {
  final inSign = norm360(lon) % 30;
  var d = inSign.floor();
  var m = ((inSign - d) * 60).round();
  if (m == 60) {
    d += 1;
    m = 0;
  }
  return '$d°${m.toString().padLeft(2, '0')}′';
}

/// Formats degrees as D°MM′ (no sign wrapping).
String formatDm(double v) {
  final s = v < 0 ? '-' : '';
  final a = v.abs();
  var d = a.floor();
  var m = ((a - d) * 60).round();
  if (m == 60) {
    d += 1;
    m = 0;
  }
  return '$s$d°${m.toString().padLeft(2, '0')}′';
}
