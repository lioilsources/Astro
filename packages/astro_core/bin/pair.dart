// Prints the relationship guide and periods of two births (plan R9, 4.3):
//   dart run astro_core:pair YYYY-MM-DD HH:MM|unknown LAT LON  YYYY-MM-DD HH:MM|unknown LAT LON  [from-year to-year]
// Times are UT.
import 'dart:io';

import 'package:astro_core/astro_core.dart';
import 'package:astro_core/content.dart';

Chart _chart(List<String> a) {
  final d = a[0].split('-').map(int.parse).toList();
  final t = a[1] == 'unknown' ? null : a[1].split(':').map(int.parse).toList();
  return Chart.compute(BirthData(
    moment: LocalMoment(year: d[0], month: d[1], day: d[2], hour: t?[0], minute: t?[1], basis: TimeBasis.ut),
    lat: double.parse(a[2]),
    lon: double.parse(a[3]),
  ));
}

String _date(double jd) => dateTimeUtcFromJd(jd).toIso8601String().substring(0, 10);

void main(List<String> args) {
  if (args.length < 8) {
    stderr.writeln('usage: pair DATE TIME|unknown LAT LON DATE TIME|unknown LAT LON [from-year to-year]');
    exit(64);
  }
  final a = _chart(args.sublist(0, 4)), b = _chart(args.sublist(4, 8));
  final now = DateTime.now().toUtc().year;
  final y0 = args.length > 8 ? int.parse(args[8]) : now - 2;
  final y1 = args.length > 9 ? int.parse(args[9]) : now + 10;
  final guide = PairGuide.of(Synastry.compute(a, b));
  print('overview');
  for (final MapEntry(:key, :value) in guide.overview.entries) {
    print('  ${key.name.padRight(8)} supportive ${value.supportive}  straining ${value.straining}');
  }
  if (guide.anyMoonUncertain) print('  moon sign uncertain (no birth time)');
  for (final c in guide.chapters) {
    if (c.blocks.isEmpty) continue;
    print('${c.id.name}  (${c.introKey})');
    for (final x in c.blocks) {
      final who = x.need != null ? (x.need!.ofFirst ? 'A ' : 'B ') : '';
      final facts = x.facts.map((f) => f.aspect.toString()).join(' · ');
      print('  ${x.linkOnly ? '→ ' : ''}$who${x.key}  ${x.weight.toStringAsFixed(2)}${facts.isEmpty ? '' : '  $facts'}');
    }
  }
  final tl = PairTimeline.compute(a, b, julianDay(y0, 1, 1, 0), julianDay(y1, 12, 31, 0));
  print('periods $y0–$y1');
  for (final p in tl.periods) {
    final s = p.series;
    print('  ${p.ofFirst ? 'A' : 'B'} ${_date(p.start)} … ${_date(p.end)}  ${p.kind.name.padRight(7)} ${pairPeriodKey(p).padRight(32)}'
        ' ${s.type.name} ${s.target.id}  w${p.weight}${p.shared ? '  shared' : ''}'
        '  exact ${s.exacts.map(_date).join(', ')}');
  }
  for (final i in tl.ingresses) {
    print('  ${i.ofFirst ? 'A' : 'B'} ${_date(i.jd)}  ${i.body.name} enters house 7');
  }
  for (final c in tl.calm) {
    print('  calm ${_date(c.start)} … ${_date(c.end)}');
  }
}
