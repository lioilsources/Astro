import 'dart:convert';
import 'dart:io';

import 'package:astro_core/astro_core.dart';
import 'package:test/test.dart';

List<Map<String, dynamic>> _load(String name) =>
    (jsonDecode(File('test/golden/$name').readAsStringSync()) as List).cast<Map<String, dynamic>>();

/// Tolerances, see docs/ephemeris.md.
const sunMinutes = 0.5;
const sunMinutesHighLat = 1.0; // |lat| > 60°: the Sun crosses the horizon at a shallow angle
const lunationSeconds = 60.0;

/// Outside 1800–2030 the two ΔT models differ by up to minutes (docs/ephemeris.md).
const lunationSecondsFarEras = 300.0;

void main() {
  test('sunrise and sunset vs skyfield + DE440', () {
    var worst = 0.0, worstHigh = 0.0, polar = 0;
    for (final row in _load('sun.json')) {
      final date = (row['date'] as List).cast<int>();
      final lat = (row['lat'] as num).toDouble(), lon = (row['lon'] as num).toDouble();
      final got = SunRiseSet.of(date[0], date[1], date[2], lat, lon);
      for (final (ref, mine) in [(row['rise'] as num?, got.rise), (row['set'] as num?, got.set)]) {
        if (ref == null) {
          expect(mine, isNull, reason: '${row['place']} $date: no crossing expected');
          polar++;
          continue;
        }
        expect(mine, isNotNull, reason: '${row['place']} $date');
        final d = (mine! - ref.toDouble()).abs() * 1440;
        if (lat.abs() > 60) {
          if (d > worstHigh) worstHigh = d;
          expect(d, lessThan(sunMinutesHighLat), reason: '${row['place']} $date: $d min');
        } else {
          if (d > worst) worst = d;
          expect(d, lessThan(sunMinutes), reason: '${row['place']} $date: $d min');
        }
      }
    }
    print('sun: worst ${(worst * 60).toStringAsFixed(1)} s, high latitudes ${(worstHigh * 60).toStringAsFixed(1)} s, polar $polar');
  });

  test('new moon, quarters and full moon vs skyfield + DE440', () {
    final rows = _load('lunations.json');
    var worst = 0.0, worstFar = 0.0;
    // Group into the spans the generator used, one engine search per span.
    final jds = [for (final r in rows) (r['jdUt'] as num).toDouble()];
    var i = 0;
    while (i < rows.length) {
      var j = i;
      while (j + 1 < rows.length && jds[j + 1] > jds[j] && jds[j + 1] - jds[j] < 10) {
        j++;
      }
      final got = Lunar.lunations(jds[i] - 2, jds[j] + 2);
      expect(got.length, j - i + 1, reason: 'span from ${jds[i]}');
      for (var k = 0; k <= j - i; k++) {
        final ref = rows[i + k];
        expect(got[k].kind.index, ref['kind']);
        final d = (got[k].jd - jds[i + k]).abs() * 86400;
        final year = decimalYearOfJd(jds[i + k]);
        final far = year < 1800 || year > 2030;
        if (far && d > worstFar) worstFar = d;
        if (!far && d > worst) worst = d;
        expect(d, lessThan(far ? lunationSecondsFarEras : lunationSeconds), reason: '${got[k]} vs ${jds[i + k]}: $d s');
      }
      i = j + 1;
    }
    print('lunations: ${rows.length}, worst ${worst.toStringAsFixed(1)} s (1800–2030), ${worstFar.toStringAsFixed(1)} s (other eras)');
  });

  test('lunar eclipses vs skyfield 2000–2030', () {
    final ref = _load('lunar_eclipses.json');
    final full = Lunar.lunations(julianDay(2000, 1, 1, 0), julianDay(2031, 1, 1, 0), kinds: {LunationKind.fullMoon});
    final flagged = full.where((l) => l.eclipse != null).toList();
    // No false alarms; Meeus ch. 54 may miss a grazing penumbral eclipse
    // (2027-07-18, penumbral magnitude ~0.001).
    for (final l in flagged) {
      expect(ref.any((r) => ((r['jdUt'] as num) - l.jd).abs() < 0.5), isTrue, reason: 'extra $l');
    }
    final missing = [for (final r in ref) if (!flagged.any((l) => ((r['jdUt'] as num) - l.jd).abs() < 0.5)) r];
    expect(missing.every((r) => r['type'] == 0), isTrue, reason: '$missing');
    expect(missing.length, lessThanOrEqualTo(1), reason: '$missing');
    for (final r in ref) {
      if (missing.contains(r)) continue;
      final jd = (r['jdUt'] as num).toDouble();
      final l = flagged.firstWhere((l) => (l.jd - jd).abs() < 0.5);
      final want = [EclipseDegree.penumbral, EclipseDegree.partial, EclipseDegree.total][r['type'] as int];
      expect(l.eclipse!.degree, want, reason: 'eclipse at $jd');
      expect((l.eclipse!.jdMax - jd).abs() * 1440, lessThan(10));
    }
  });
}
