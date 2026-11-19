import 'angles.dart';
import 'ephemeris.dart';
import 'model.dart';

/// Longitudes of one body sampled at a fixed step and interpolated (4-point
/// Lagrange on the unwrapped longitude). Makes searches cheap: one ephemeris
/// evaluation per sample instead of per query.
class LongitudeTrack {
  final Body body;
  final double t0;
  final double step;
  final List<double> _u;

  LongitudeTrack._(this.body, this.t0, this.step, this._u);

  factory LongitudeTrack.build(Body body, double from, double to, double step) {
    final start = from - 2 * step;
    final n = ((to - from) / step).ceil() + 5;
    final u = List<double>.filled(n, 0);
    var prev = Ephemeris.longitude(body, start);
    u[0] = prev;
    for (var i = 1; i < n; i++) {
      final l = Ephemeris.longitude(body, start + i * step);
      u[i] = u[i - 1] + angDiff(l, prev);
      prev = l;
    }
    return LongitudeTrack._(body, start, step, u);
  }

  double get start => t0 + step;
  double get end => t0 + (_u.length - 3) * step;
  int get length => _u.length;
  double timeAt(int i) => t0 + i * step;

  /// Longitude 0..360 of sample [i].
  double sample(int i) => norm360(_u[i]);

  /// Interpolated longitude 0..360 at [t].
  double at(double t) => norm360(unwrappedAt(t));

  double unwrappedAt(double t) {
    final f = (t - t0) / step;
    var i = f.floor();
    if (i < 1) i = 1;
    if (i > _u.length - 3) i = _u.length - 3;
    final x = f - i;
    final w0 = -x * (x - 1) * (x - 2) / 6;
    final w1 = (x + 1) * (x - 1) * (x - 2) / 2;
    final w2 = -(x + 1) * x * (x - 2) / 2;
    final w3 = (x + 1) * x * (x - 1) / 6;
    return w0 * _u[i - 1] + w1 * _u[i] + w2 * _u[i + 1] + w3 * _u[i + 2];
  }

  /// Degrees per day at [t].
  double speedAt(double t) => (unwrappedAt(t + 0.01) - unwrappedAt(t - 0.01)) / 0.02;
}
