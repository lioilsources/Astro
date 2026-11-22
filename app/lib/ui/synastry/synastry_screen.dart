import 'package:astro_core/astro_core.dart';
import 'package:astro_core/content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/content_repository.dart';
import '../../data/profile.dart';
import '../../l10n/app_localizations.dart';
import '../../logic/compute.dart';
import '../../export/pair_pdf.dart';
import '../../logic/synastry_reading.dart';
import '../../pair_state.dart';
import '../../state.dart';
import '../entry_view.dart';
import '../format.dart';
import '../wheel.dart';
import 'pair_guide_tab.dart';
import 'pair_names.dart';
import 'pair_periods_tab.dart';

/// Picks two saved profiles and the kind of relationship (plan 10.4);
/// "Porovnat" saves the pair (plan R9 6.1) and opens it.
class SynastryScreen extends ConsumerStatefulWidget {
  const SynastryScreen({super.key});
  @override
  ConsumerState<SynastryScreen> createState() => _SynastryScreenState();
}

class _SynastryScreenState extends ConsumerState<SynastryScreen> {
  String? _first, _second;
  Relationship _relationship = Relationship.partner;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final profiles = ref.watch(profilesProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l.synastryTitle)),
      body: profiles.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (list) {
          if (list.length < 2) {
            return Center(child: Padding(padding: const EdgeInsets.all(32), child: Text(l.synastryNeedTwo, textAlign: TextAlign.center)));
          }
          final ids = {for (final p in list) p.id};
          final first = ids.contains(_first) ? _first! : list[0].id;
          final second = ids.contains(_second) ? _second! : list[1].id;
          Profile byId(String id) => list.firstWhere((p) => p.id == id);
          DropdownButtonFormField<String> picker(String label, String value, ValueChanged<String?> onChanged) => DropdownButtonFormField<String>(
                initialValue: value,
                isExpanded: true,
                decoration: InputDecoration(labelText: label),
                items: [for (final p in list) DropdownMenuItem(value: p.id, child: Text(p.name))],
                onChanged: onChanged,
              );
          return ListView(padding: const EdgeInsets.all(16), children: [
            Text(l.synastryIntro, style: t.bodyMedium),
            const SizedBox(height: 16),
            picker(l.synastryFirst, first, (v) => setState(() => _first = v)),
            const SizedBox(height: 12),
            picker(l.synastrySecond, second, (v) => setState(() => _second = v)),
            const SizedBox(height: 20),
            Text(l.synastryRelationship, style: t.labelLarge),
            const SizedBox(height: 6),
            Wrap(spacing: 6, runSpacing: 4, children: [
              for (final r in Relationship.values)
                ChoiceChip(
                  label: Text(l.relationshipName(r.name)),
                  selected: r == _relationship,
                  onSelected: (_) => setState(() => _relationship = r),
                ),
            ]),
            const SizedBox(height: 20),
            if (first == second) Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(l.synastrySamePerson, style: t.bodySmall)),
            FilledButton(
              onPressed: first == second
                  ? null
                  : () async {
                      final a = byId(first), b = byId(second), r = _relationship;
                      final nav = Navigator.of(context);
                      await ref.read(pairsProvider.notifier).add(a.id, b.id, r);
                      nav.pushReplacement(MaterialPageRoute(builder: (_) => SynastryResultScreen(a, b, r)));
                    },
              child: Text(l.synastryCompare),
            ),
          ]);
        },
      ),
    );
  }
}

/// Guide, periods, bi-wheel, inter-chart tables and the pair reading (plan R9 6.2).
class SynastryResultScreen extends ConsumerStatefulWidget {
  final Profile first;
  final Profile second;
  final Relationship relationship;
  const SynastryResultScreen(this.first, this.second, this.relationship, {super.key});
  @override
  ConsumerState<SynastryResultScreen> createState() => _SynastryResultScreenState();
}

class _SynastryResultScreenState extends ConsumerState<SynastryResultScreen> {
  Future<Synastry>? _future;
  PairTimeline? _timeline;
  late final double _now = jdFromDateTimeUtc(DateTime.now().toUtc());

  bool get _partner => widget.relationship.showsPartnerLayer;

  @override
  void initState() {
    super.initState();
    final a = ref.read(chartProvider(widget.first)), b = ref.read(chartProvider(widget.second));
    _future = Compute.synastry(a, b);
    Compute.pairTimeline(a, b, _now).then((tl) {
      if (mounted) setState(() => _timeline = tl);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final content = ref.watch(contentProvider).value ?? const ContentRepository({}, []);
    final names = PairNames(widget.first.name, widget.second.name);
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l.synastryPairTitle(widget.first.name, widget.second.name)),
          actions: [
            FutureBuilder<Synastry>(
              future: _future,
              builder: (context, snap) => IconButton(
                tooltip: l.pairSharePdf,
                icon: const Icon(Icons.ios_share),
                onPressed: snap.data == null || _timeline == null
                    ? null
                    : () => sharePairPdf(l, names, PairGuide.of(snap.data!), _timeline!, content, ref.read(filterProvider),
                        relationship: widget.relationship, now: _now),
              ),
            ),
          ],
          bottom: TabBar(labelPadding: const EdgeInsets.symmetric(horizontal: 4), tabs: [
            Tab(text: l.tabGuide),
            Tab(text: l.tabPeriods),
            Tab(text: l.tabWheel),
            Tab(text: l.tabTables),
            Tab(text: l.tabReading),
          ]),
        ),
        body: FutureBuilder<Synastry>(
          future: _future,
          builder: (context, snap) {
            if (snap.hasError) return Center(child: Text('${snap.error}'));
            final s = snap.data;
            if (s == null) return const Center(child: CircularProgressIndicator());
            final v = _PairView(s, widget.first.name, widget.second.name, widget.relationship, content);
            return TabBarView(children: [
              Builder(
                builder: (context) => PairGuideTab(
                  guide: PairGuide.of(s),
                  timeline: _timeline,
                  names: names,
                  content: content,
                  showPartner: _partner,
                  now: _now,
                  onOpenTimeline: () => DefaultTabController.of(context).animateTo(1),
                  leading: v._twins(context),
                ),
              ),
              PairPeriodsTab(timeline: _timeline, names: names, content: content, now: _now),
              v.wheel(context),
              v.tables(context),
              v.reading(context),
            ]);
          },
        ),
      ),
    );
  }
}

class _PairView {
  final Synastry s;
  final String firstName;
  final String secondName;
  final Relationship relationship;
  final ContentRepository content;
  const _PairView(this.s, this.firstName, this.secondName, this.relationship, this.content);

  bool get _partner => relationship.showsPartnerLayer;

  /// Same-planet conjunctions of twins are replaced by the twins card.
  List<Aspect> get _aspects => [
        for (final a in s.aspects)
          if (!(s.twins != null && a.type == AspectType.conjunction && a.a == a.b)) a,
      ];

  String _pt(AppLocalizations l, ChartPoint p, bool ofFirst) => l.synastryPointOf(l.point(p), ofFirst ? firstName : secondName);

  String _aspectTitle(AppLocalizations l, Aspect a) => '${_pt(l, a.a, true)} ${l.aspect(a.type)} ${_pt(l, a.b, false)}';

  String _overlayTitle(AppLocalizations l, HouseOverlay o) =>
      '${l.synastryPointOf(l.body(o.body), o.ofFirst ? firstName : secondName)} – '
      '${l.synastryPointOf(l.houseN(o.house), o.ofFirst ? secondName : firstName)}';

  String _factTitle(AppLocalizations l, Factor f) => f.aspect != null ? _aspectTitle(l, f.aspect!) : _overlayTitle(l, f.overlay!);

  void _open(BuildContext context, String key, String title) =>
      showEntry(context, content[key], title: title, showPartner: _partner);

  List<Widget> _twins(BuildContext context) => s.twins == null ? const [] : [TwinsCard(s.twins!, content), const SizedBox(height: 12)];

  Widget wheel(BuildContext context) {
    final l = AppLocalizations.of(context);
    final second = s.second;
    return ListView(padding: const EdgeInsets.all(16), children: [
      ..._twins(context),
      ChartWheel(
        s.first,
        outer: {for (final b in Body.planets) if (second.positions[b] != null) b: second.positions[b]!.lon},
        crossAspects: [for (final a in _aspects) if (!a.a.isAngle && !a.b.isAngle) a],
      ),
      const SizedBox(height: 8),
      Text(l.synastryWheelLegend(firstName, secondName), style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
    ]);
  }

  Widget tables(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    Widget header(String title, {String? glossary}) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 8, 4),
          child: Row(children: [
            Expanded(child: Text(title, style: t.titleMedium)),
            if (glossary != null)
              IconButton(
                icon: const Icon(Icons.help_outline, size: 20),
                onPressed: () => showEntry(context, content['glossary/$glossary'], title: title),
              ),
          ]),
        );
    Widget note(String text) => Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text(text, style: t.bodySmall));
    List<Widget> overlays(bool ofFirst) {
      final host = ofFirst ? s.second : s.first;
      final rows = s.overlays.where((o) => o.ofFirst == ofFirst).toList();
      return [
        header(l.synastryHousesOf(ofFirst ? firstName : secondName, ofFirst ? secondName : firstName), glossary: 'house'),
        if (host.houses == null || !host.houses!.defined) note(l.synastryNoHouses(ofFirst ? secondName : firstName)),
        for (final o in rows)
          ListTile(
            dense: true,
            leading: SizedBox(width: 28, child: Center(child: glyphText(bodyGlyph[o.body]!, size: 20))),
            title: Text(_overlayTitle(l, o)),
            onTap: () => _open(context, synastryHouseKey(o), _overlayTitle(l, o)),
          ),
      ];
    }

    final aspects = _aspects;
    return ListView(children: [
      if (s.twins != null) Padding(padding: const EdgeInsets.fromLTRB(16, 16, 16, 0), child: TwinsCard(s.twins!, content)),
      header(l.synastryAspects, glossary: 'synastry'),
      if (aspects.isEmpty) note(l.synastryNoAspects),
      for (final a in aspects)
        ListTile(
          dense: true,
          leading: SizedBox(width: 28, child: Center(child: glyphText(aspectGlyph[a.type]!, size: 18))),
          title: Text(_aspectTitle(l, a)),
          subtitle: Text('orb ${formatDm(a.orb)}'),
          onTap: () => _open(context, synastryKey(a), _aspectTitle(l, a)),
          onLongPress: () => showEntry(context, content['glossary/${a.type.name}'], title: l.aspect(a.type)),
        ),
      ...overlays(true),
      ...overlays(false),
      const SizedBox(height: 32),
    ]);
  }

  Widget reading(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    String title(String id) => switch (id) {
          'aspects' => l.sectionSynastryAspects,
          'points' => l.sectionSynastryPoints,
          _ => l.sectionSynastryHouses,
        };
    return ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 32), children: [
      ..._twins(context),
      for (final sec in synastrySections(s, content)) ...[
        Padding(padding: const EdgeInsets.only(top: 20, bottom: 4), child: Text(title(sec.id), style: t.titleLarge)),
        for (final i in sec.items) ...[
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(i.facts.map((f) => _factTitle(l, f)).join(' · '), style: t.labelMedium),
          ),
          EntryView(i.entry, fallbackTitle: _factTitle(l, i.facts.first), showPartner: _partner),
        ],
      ],
    ]);
  }
}

/// Near-identical charts (plan 10.4): what differs instead of ten conjunctions.
class TwinsCard extends StatelessWidget {
  final TwinsDiff twins;
  final ContentRepository content;
  const TwinsCard(this.twins, this.content, {super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final d = twins;
    final cusps = d.cuspDiffs?.map((x) => x.abs()).toList();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(l.twinsTitle, style: t.titleMedium),
          const SizedBox(height: 6),
          Text(l.twinsBody(formatDm(d.maxPlanetDiff), d.minutesApart.round().toString()), style: t.bodyMedium),
          const SizedBox(height: 6),
          if (d.ascDiff == null)
            Text(l.twinsNoTime, style: t.bodyMedium)
          else ...[
            Text(l.twinsAxes(formatDm(d.ascDiff!.abs()), formatDm(d.mcDiff!.abs())), style: t.bodyMedium),
            if (cusps != null) Text(l.twinsCusps(formatDm(cusps.reduce((a, b) => a < b ? a : b)), formatDm(cusps.reduce((a, b) => a > b ? a : b))), style: t.bodyMedium),
            if (cusps != null && d.houseChanges.isEmpty) Text(l.twinsNoHouseChange, style: t.bodyMedium),
            for (final MapEntry(key: b, value: (from, to)) in d.houseChanges.entries)
              Text(l.twinsHouseChange(l.body(b), '$from', '$to'), style: t.bodyMedium),
          ],
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => showEntry(context, content['glossary/twins'], title: l.twinsGlossary),
              child: Text(l.twinsGlossary),
            ),
          ),
        ]),
      ),
    );
  }
}
