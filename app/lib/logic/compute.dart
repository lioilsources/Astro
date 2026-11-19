import 'dart:isolate';

import 'package:astro_core/astro_core.dart';

/// Heavy computations off the UI thread.
class Compute {
  static Future<List<TransitEvent>> events(Chart natal, double from, double to, {List<Body>? bodies}) =>
      Isolate.run(() => TransitEngine(natal).events(from, to, bodies: bodies));

  static Future<List<HouseIngress>> ingresses(Chart natal, double from, double to) =>
      Isolate.run(() => TransitEngine(natal).ingresses(from, to));

  /// Daily tension from birth until [until] (at most 100 years).
  static Future<List<double>> lifeTension(Chart natal, double until) => Isolate.run(() {
        final from = natal.time.jdUt;
        final days = (until - from).clamp(1, 36525).floor();
        return TransitEngine(natal).tensionSeries(from, days);
      });
}
