import 'package:astro_core/astro_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/profile.dart';
import '../../export/pdf_export.dart';
import '../../l10n/app_localizations.dart';
import '../../state.dart';
import '../format.dart';
import '../journal/journal_screen.dart';
import '../profile_form.dart';
import 'patterns_view.dart';
import 'reading_tab.dart';
import 'stars_view.dart';
import 'tables_tab.dart';
import 'time_tab.dart';

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
                tooltip: l.journalTitle,
                icon: const Icon(Icons.event_note_outlined),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => JournalScreen(current, chart))),
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
          BlindGate(current, chart, child: TimeTab(chart, current)),
        ]),
      ),
    );
  }
}

class _Overview extends StatefulWidget {
  final Chart chart;
  final Profile profile;
  const _Overview(this.chart, this.profile);

  @override
  State<_Overview> createState() => _OverviewState();
}

class _OverviewState extends State<_Overview> {
  /// Pattern highlighted on the wheel (tap a chip to toggle).
  ChartPattern? _highlight;

  @override
  Widget build(BuildContext context) {
    final chart = widget.chart, profile = widget.profile;
    final l = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final sun = chart.positions[Body.sun]!, moon = chart.positions[Body.moon]!;
    final asc = chart.asc;
    final moonDayChange = !chart.timeKnown && _moonChangesSign(chart);
    final shapes = chart.patterns.where((p) => p.kind.isShape).toList();
    final highlight = shapes.contains(_highlight) ? _highlight : null;
    return ListView(padding: const EdgeInsets.all(16), children: [
      WheelWithStars(chart, highlight: highlight),
      if (shapes.isNotEmpty) ...[
        const SizedBox(height: 8),
        Wrap(spacing: 6, runSpacing: 4, children: [
          for (final p in shapes)
            ChoiceChip(
              label: Text(l.pattern(p)),
              selected: identical(p, highlight),
              onSelected: (on) => setState(() => _highlight = on ? p : null),
            ),
        ]),
      ],
      const SizedBox(height: 16),
      Text(l.oneSentence, style: t.labelLarge),
      Text(
        l.overviewLine(l.sign(sun.sign), l.sign(moon.sign), asc == null ? '' : ', ${l.bodyName('asc')} ${l.sign(Sign.ofLongitude(asc))}'),
        style: t.titleMedium,
      ),
      const SizedBox(height: 12),
      if (profile.catalogReliability != null) ...[
        Text('${l.reliability}: ${l.reliabilityBadge(profile.catalogReliability!)}', style: t.labelLarge),
        if (const ['B', 'C'].contains(profile.catalogReliability))
          Text(l.reliabilityWarning(profile.catalogReliability!),
              style: t.bodySmall?.copyWith(color: profile.catalogReliability == 'C' ? Theme.of(context).colorScheme.error : null)),
        if (profile.catalogSource != null) Text('${l.source}: ${profile.catalogSource}', style: t.bodySmall),
        const SizedBox(height: 8),
      ],
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
