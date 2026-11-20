// Rough timings of the transit engine: dart run astro_core:bench
import 'package:astro_core/astro_core.dart';

void main() {
  final natal = Chart.compute(const BirthData(
      moment: LocalMoment(year: 2000, month: 1, day: 1, hour: 12, minute: 0, basis: TimeBasis.ut), lat: 50.08, lon: 14.42));
  final e = TransitEngine(natal);
  final from = julianDay(2026, 11, 1, 0);
  var sw = Stopwatch()..start();
  final ev = e.events(from, from + 30);
  print('month, all bodies: ${ev.length} events in ${sw.elapsedMilliseconds} ms');
  sw = Stopwatch()..start();
  final series = e.tensionSeries(julianDay(1946, 1, 1, 12), 365 * 80);
  print('tension: ${series.length} days in ${sw.elapsedMilliseconds} ms');
  sw = Stopwatch()..start();
  for (var i = 0; i < 1000; i++) {
    Ephemeris.longitude(Body.values[i % 10], from + i);
  }
  print('1000 longitudes: ${sw.elapsedMilliseconds} ms');
}
