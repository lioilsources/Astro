import 'dart:isolate';

import 'package:astro_core/astro_core.dart';

/// Heavy computations off the UI thread.
class Compute {
  static Future<List<TransitEvent>> events(Chart natal, double from, double to, {List<Body>? bodies}) =>
      Isolate.run(() => TransitEngine(natal).events(from, to, bodies: bodies));

  static Future<List<HouseIngress>> ingresses(Chart natal, double from, double to) =>
      Isolate.run(() => TransitEngine(natal).ingresses(from, to));

  /// Moon events of a period: exact lunations (with eclipses), sign ingresses,
  /// void-of-course periods (plan 10.2).
  static Future<MoonData> moon(double from, double to, {bool traditionalOnly = false}) => Isolate.run(() => MoonData(
        Lunar.lunations(from, to),
        Lunar.ingresses(from, to),
        Lunar.voidOfCourse(from, to, traditionalOnly: traditionalOnly),
      ));

  /// Planetary days of the local dates [first] … [first] + [days] − 1 at [place];
  /// null entries where the Sun does not rise or set.
  static Future<List<PlanetaryDay?>> planetaryDays(DateTime first, int days, GeoLocation place) => Isolate.run(() => [
        for (var i = 0; i < days; i++)
          () {
            final d = DateTime.utc(first.year, first.month, first.day + i);
            return PlanetaryHours.day(d.year, d.month, d.day, place.lat, place.lon);
          }(),
      ]);

  /// Daily tension from birth until [until] (at most 100 years).
  static Future<List<double>> lifeTension(Chart natal, double until) => Isolate.run(() {
        final from = natal.time.jdUt;
        final days = (until - from).clamp(1, 36525).floor();
        return TransitEngine(natal).tensionSeries(from, days);
      });
}

class MoonData {
  final List<Lunation> lunations;
  final List<MoonIngress> ingresses;
  final List<VoidOfCourse> voids;
  const MoonData(this.lunations, this.ingresses, this.voids);
}
