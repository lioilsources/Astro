import 'package:astro_core/astro_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/profile.dart';
import '../../export/pdf_export.dart';
import '../../l10n/app_localizations.dart';
import '../../state.dart';
import '../format.dart';
import '../profile_form.dart';
import '../wheel.dart';
import 'reading_tab.dart';
import 'tables_tab.dart';
import 'transits_tab.dart';

class ChartScreen extends ConsumerWidget {
  final Profile profile;
  const ChartScreen(this.profile, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    // Re-read the profile so edits show up.
    final current = ref.watch(profilesProvider).value?.where((p) => p.id == profile.id).firstOrNull ?? profile;
    final chart = ref.watch(chartProvider(current));
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text(current.name),
          actions: [
            IconButton(
              tooltip: l.shareFull,
              icon: const Icon(Icons.ios_share),
              onPressed: () async {
                final content = await ref.read(contentProvider.future);
                if (context.mounted) await shareFullReading(context, current, chart, content);
              },
            ),
            if (current.catalogId == null)
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileForm(existing: current))),
              ),
          ],
          bottom: TabBar(isScrollable: true, tabs: [
            Tab(text: l.tabOverview),
            Tab(text: l.tabTables),
            Tab(text: l.tabReading),
            Tab(text: l.tabTransits),
          ]),
        ),
        body: TabBarView(children: [
          _Overview(chart, current),
          TablesTab(chart),
          ReadingTab(chart, current),
          TransitsTab(chart, current),
        ]),
      ),
    );
  }
}

class _Overview extends StatelessWidget {
  final Chart chart;
  final Profile profile;
  const _Overview(this.chart, this.profile);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final sun = chart.positions[Body.sun]!, moon = chart.positions[Body.moon]!;
    final asc = chart.asc;
    final moonDayChange = !chart.timeKnown && _moonChangesSign(chart);
    return ListView(padding: const EdgeInsets.all(16), children: [
      ChartWheel(chart),
      const SizedBox(height: 16),
      Text(l.oneSentence, style: t.labelLarge),
      Text(
        l.overviewLine(l.sign(sun.sign), l.sign(moon.sign), asc == null ? '' : ', ${l.bodyName('asc')} ${l.sign(Sign.ofLongitude(asc))}'),
        style: t.titleMedium,
      ),
      const SizedBox(height: 12),
      if (!chart.timeKnown) Text(l.noHouses, style: t.bodySmall),
      if (moonDayChange) Text(l.moonUncertain, style: t.bodySmall),
      if (chart.houseDefault.warnUnequal && profile.houseSystem == null) Text(l.unequalHousesWarning, style: t.bodySmall),
      if (chart.houses != null && !chart.houses!.defined) Text(l.polarHouses, style: t.bodySmall),
      const SizedBox(height: 8),
      Text(
        '${_offset(chart.time)} · JD ${chart.time.jdUt.toStringAsFixed(4)}'
        '${chart.houses != null ? ' · ${l.house(chart.houses!.system)}' : ''}',
        style: t.bodySmall,
      ),
    ]);
  }

  static String _offset(ResolvedTime t) {
    if (t.basisUsed == TimeBasis.ut) return 'UT';
    final h = t.offsetHours;
    final hh = h.abs().floor(), mm = ((h.abs() - hh) * 60).round();
    return '${t.abbreviation ?? ''} (UT${h < 0 ? '−' : '+'}$hh${mm == 0 ? '' : ':${two(mm)}'})';
  }

  static bool _moonChangesSign(Chart c) {
    final noon = c.time.jdUt;
    final a = Ephemeris.longitude(Body.moon, noon - 0.5), b = Ephemeris.longitude(Body.moon, noon + 0.5);
    return Sign.ofLongitude(a) != Sign.ofLongitude(b);
  }
}
