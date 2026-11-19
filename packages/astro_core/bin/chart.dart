// Prints a natal chart: dart run astro_core:chart YYYY-MM-DD HH:MM LAT LON [ZONE|UT|LMT] [system]
import 'dart:io';

import 'package:astro_core/astro_core.dart';

void main(List<String> args) {
  if (args.length < 4) {
    stderr.writeln('usage: chart YYYY-MM-DD HH:MM|unknown LAT LON [Europe/Prague|UT|LMT] [placidus|koch|…]');
    exit(64);
  }
  final d = args[0].split('-').map(int.parse).toList();
  final known = args[1] != 'unknown';
  final t = known ? args[1].split(':').map(int.parse).toList() : null;
  final basisArg = args.length > 4 ? args[4] : 'UT';
  final basis = switch (basisArg) { 'UT' => TimeBasis.ut, 'LMT' => TimeBasis.lmt, _ => TimeBasis.zone };
  final moment = LocalMoment(
    year: d[0],
    month: d[1],
    day: d[2],
    hour: t?[0],
    minute: t?[1],
    calendar: defaultCalendar(d[0], d[1], d[2]),
    basis: basis,
    zone: basis == TimeBasis.zone ? basisArg : null,
  );
  final system = args.length > 5 ? HouseSystem.values.byName(args[5]) : null;
  final chart = Chart.compute(
    BirthData(moment: moment, lat: double.parse(args[2]), lon: double.parse(args[3])),
    options: ChartOptions(houseSystem: system),
  );
  print('JD(UT) ${chart.time.jdUt.toStringAsFixed(5)}  offset ${chart.time.offsetHours}h ${chart.time.abbreviation}');
  for (final b in chart.bodies) {
    final p = chart.positions[b]!;
    final st = chart.states[b];
    print('${b.name.padRight(9)} ${p.lon.toStringAsFixed(4).padLeft(9)}  ${formatInSign(p.lon).padLeft(7)} ${p.sign.name.padRight(12)}'
        ' lat ${p.lat.toStringAsFixed(3).padLeft(7)} v ${p.speed.toStringAsFixed(4).padLeft(8)}${p.retrograde ? ' R' : '  '}'
        ' house ${chart.houseOf(b) ?? '-'}${st == null ? '' : '  ${st.dignity.name} ${st.score}'}');
  }
  final h = chart.houses;
  if (h != null) {
    print('system ${h.system.name}${chart.houseDefault.warnUnequal ? ' (unequal houses warning)' : ''}');
    if (h.cusps == null) {
      print('houses undefined at this latitude');
    } else {
      for (var i = 0; i < 12; i++) {
        print('H${i + 1}'.padRight(4) + h.cusps![i].toStringAsFixed(4).padLeft(9));
      }
    }
  }
  for (final a in chart.aspects) {
    print(a);
  }
  if (chart.missing.isNotEmpty) print('missing: ${chart.missing.map((b) => b.name).join(', ')}');
}
