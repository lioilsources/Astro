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

  /// Inter-chart aspects and house overlays of two people (plan 10.4).
  static Future<Synastry> synastry(Chart first, Chart second) => Isolate.run(() => Synastry.compute(first, second));
}

/// R5 (plan 10.5): secondary progressions and solar returns.
class Progressions {
  /// Progressions read for one moment of life.
  static Future<Progression> at(Chart natal, double lifeJd) => Isolate.run(() => Progression.at(natal, lifeJd));

  /// Life timeline: progressed milestones and the solar returns from birth to [years] of age.
  static Future<LifeTimeline> timeline(Chart natal, {int years = 100}) => Isolate.run(() {
        final first = dateTimeUtcFromJd(natal.time.jdUt).year + 1;
        return LifeTimeline(progressedMilestones(natal, years: years.toDouble()), [
          for (var y = first; y <= first + years - 1; y++) SolarReturn.ofYear(natal, y),
        ]);
      });

  /// Solar return of [year] and its chart at [place].
  static Future<({SolarReturn sr, Chart chart})> solarReturn(Chart natal, int year, GeoLocation place, ChartOptions options) =>
      Isolate.run(() {
        final sr = SolarReturn.ofYear(natal, year);
        return (sr: sr, chart: sr.chartAt(place, options: options));
      });
}

class LifeTimeline {
  final List<LifeMilestone> milestones;
  final List<SolarReturn> solarReturns;
  const LifeTimeline(this.milestones, this.solarReturns);
}

class MoonData {
  final List<Lunation> lunations;
  final List<MoonIngress> ingresses;
  final List<VoidOfCourse> voids;
  const MoonData(this.lunations, this.ingresses, this.voids);
}
