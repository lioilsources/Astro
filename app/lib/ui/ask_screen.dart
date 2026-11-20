import 'package:astro_core/astro_core.dart';
import 'package:astro_core/content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/profile.dart';
import '../l10n/app_localizations.dart';
import '../logic/compute.dart';
import '../logic/queries.dart';
import '../state.dart';
import 'election_screen.dart';
import 'entry_view.dart';
import 'format.dart';

/// Queries of plan 3.5: trait → chart ("co to vysvětluje?") and event → transits.
class AskScreen extends ConsumerStatefulWidget {
  const AskScreen({super.key});
  @override
  ConsumerState<AskScreen> createState() => _AskScreenState();
}

class _AskScreenState extends ConsumerState<AskScreen> {
  String? _profileId;
  bool _eventMode = false;
  final _trait = TextEditingController();
  final _label = TextEditingController();
  DateTime _date = DateTime.now();
  TraitAnswer? _answer;
  Future<_EventAnswer>? _event;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final profiles = ref.watch(profilesProvider).value ?? const <Profile>[];
    final profile = profiles.where((p) => p.id == _profileId).firstOrNull ?? profiles.firstOrNull;
    return Scaffold(
      appBar: AppBar(title: Text(l.navAsk), actions: [
        IconButton(
          tooltip: l.electionTitle,
          icon: const Icon(Icons.event_available),
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ElectionScreen())),
        ),
      ]),
      body: profile == null
          ? Center(child: Padding(padding: const EdgeInsets.all(32), child: Text(l.profilesEmpty, textAlign: TextAlign.center)))
          : ListView(padding: const EdgeInsets.all(16), children: [
              DropdownButtonFormField<String>(
                initialValue: profile.id,
                decoration: InputDecoration(labelText: l.pickProfile),
                items: [for (final p in profiles) DropdownMenuItem(value: p.id, child: Text(p.name))],
                onChanged: (v) => setState(() {
                  _profileId = v;
                  _answer = null;
                  _event = null;
                }),
              ),
              const SizedBox(height: 12),
              SegmentedButton<bool>(
                segments: [ButtonSegment(value: false, label: Text(l.askTrait)), ButtonSegment(value: true, label: Text(l.askEvent))],
                selected: {_eventMode},
                onSelectionChanged: (s) => setState(() => _eventMode = s.first),
              ),
              const SizedBox(height: 12),
              Text(l.connectionsNotProof, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 12),
              if (!_eventMode) ..._traitUi(context, profile) else ..._eventUi(context, profile),
            ]),
    );
  }

  List<Widget> _traitUi(BuildContext context, Profile profile) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final content = ref.watch(contentProvider).value;
    void run([String? q]) {
      if (content == null) return;
      if (q != null) _trait.text = q;
      setState(() => _answer = askTrait(_trait.text, ref.read(chartProvider(profile)), content));
    }

    final a = _answer;
    Widget column(String title, List<TraitMatch> list) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: t.titleMedium),
          if (list.isEmpty) const Text('—'),
          for (final m in list)
            ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: Text(m.entry.title),
              subtitle: Text(m.layer == 'shadow' ? l.shadowTitle : ''),
              trailing: Text(m.factor.weight.toStringAsFixed(2)),
              onTap: () => showEntry(context, m.entry),
            ),
        ]);
    return [
      TextField(
        controller: _trait,
        decoration: InputDecoration(labelText: l.askTrait, hintText: l.askTraitHint, suffixIcon: IconButton(icon: const Icon(Icons.search), onPressed: run)),
        onSubmitted: (_) => run(),
      ),
      const SizedBox(height: 16),
      if (a != null && a.trait == null) ...[
        Text(l.didYouMean),
        Wrap(spacing: 8, children: [for (final s in a.suggestions) ActionChip(label: Text(s.name), onPressed: () => run(s.name))]),
      ],
      if (a != null && a.trait != null) ...[
        Text('${a.trait!.name}${a.trait!.opposite != null ? ' ↔ ${content?.trait(a.trait!.opposite!)?.name ?? ''}' : ''}', style: t.titleLarge),
        if (a.supports.isEmpty && a.against.isEmpty) Text(l.noTraitMatch),
        const SizedBox(height: 8),
        column(l.supports, a.supports),
        const SizedBox(height: 16),
        column(l.speaksAgainst, a.against),
      ],
    ];
  }

  List<Widget> _eventUi(BuildContext context, Profile profile) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    return [
      TextField(controller: _label, decoration: InputDecoration(labelText: l.askEventHint)),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(child: Text(fmtDateTime(_date))),
        TextButton(
          onPressed: () async {
            final d = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(1600), lastDate: DateTime(2199));
            if (d == null || !context.mounted) return;
            final tm = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_date));
            setState(() => _date = DateTime(d.year, d.month, d.day, tm?.hour ?? 12, tm?.minute ?? 0));
          },
          child: Text(l.pickDate),
        ),
        FilledButton(
          onPressed: () {
            final chart = ref.read(chartProvider(profile));
            setState(() => _event = _computeEvent(chart, jdFromDateTimeUtc(_date.toUtc())));
            if (_label.text.trim().isNotEmpty) {
              final ev = LifeEvent(DateTime.now().microsecondsSinceEpoch.toRadixString(36), jdFromDateTimeUtc(_date.toUtc()), _label.text.trim());
              ref.read(profilesProvider.notifier).upsert(profile.copyWith(events: [...profile.events, ev]));
            }
          },
          child: const Icon(Icons.search),
        ),
      ]),
      if (profile.events.isNotEmpty)
        Wrap(spacing: 8, children: [
          for (final e in profile.events)
            ActionChip(
              label: Text('${e.label} ${fmtDate(localOfJd(e.jdUt))}'),
              onPressed: () => setState(() {
                _date = localOfJd(e.jdUt);
                _label.text = e.label;
                _event = _computeEvent(ref.read(chartProvider(profile)), e.jdUt);
              }),
            ),
        ]),
      const SizedBox(height: 12),
      if (_event != null)
        FutureBuilder<_EventAnswer>(
          future: _event,
          builder: (context, snap) {
            if (!snap.hasData) return Text(snap.hasError ? '${snap.error}' : l.computing);
            final a = snap.data!;
            final content = ref.watch(contentProvider).value;
            Widget list(String title, List<TransitEvent> evs) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, style: t.titleMedium),
                  if (evs.isEmpty) const Text('—'),
                  for (final e in evs)
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(l.transitTitle(l.body(e.transiting), l.aspect(e.type), l.point(e.target))),
                      subtitle: Text('${l.strength} ${a.engine.strengthAt(e, a.jd, concurrent: a.events)} · '
                          '${recurrenceYears(e) >= 1 ? '~${recurrenceYears(e).toStringAsFixed(recurrenceYears(e) < 10 ? 1 : 0)} r.' : ''} · '
                          '${((e.end - e.start)).toStringAsFixed(e.end - e.start < 2 ? 2 : 0)} d'),
                      onTap: () => showEntry(context, content?[transitKey(e)], title: '${l.body(e.transiting)} ${l.aspect(e.type)} ${l.point(e.target)}'),
                    ),
                ]);
            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (a.percentile != null) Text(l.dayPercentile(a.percentile!), style: t.titleMedium),
              const SizedBox(height: 8),
              list(l.tense, a.events.where(isTenseTransit).toList()),
              const SizedBox(height: 12),
              list(l.harmonious, a.events.where((e) => !isTenseTransit(e)).toList()),
            ]);
          },
        ),
    ];
  }

  final Map<String, List<double>> _tensionCache = {};

  Future<_EventAnswer> _computeEvent(Chart chart, double jd) async {
    final engine = TransitEngine(chart);
    final events = (await Compute.events(chart, jd - 0.01, jd + 0.01)).where((e) => e.covers(jd)).toList()
      ..sort((a, b) => engine.strengthAt(b, jd).compareTo(engine.strengthAt(a, jd)));
    int? pct;
    if (jd > chart.time.jdUt) {
      final key = '${chart.time.jdUt}-${chart.birth.lat}-${chart.birth.lon}';
      final now = jdFromDateTimeUtc(DateTime.now().toUtc());
      final series = _tensionCache[key] ??= await Compute.lifeTension(chart, now > jd ? now : jd + 1);
      pct = percentileOf(series, engine.tensionAt(jd));
    }
    return _EventAnswer(engine, jd, events, pct);
  }
}

class _EventAnswer {
  final TransitEngine engine;
  final double jd;
  final List<TransitEvent> events;
  final int? percentile;
  const _EventAnswer(this.engine, this.jd, this.events, this.percentile);
}
