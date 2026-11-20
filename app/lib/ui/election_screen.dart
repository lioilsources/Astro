import 'package:astro_core/astro_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/profile.dart';
import '../export/ics_export.dart';
import '../l10n/app_localizations.dart';
import '../logic/election.dart';
import '../state.dart';
import 'chart/chart_screen.dart';
import 'entry_view.dart';
import 'format.dart';

/// "Najdi termín" (plan 10.7): intent + period → windows best by traditional rules.
class ElectionScreen extends ConsumerStatefulWidget {
  const ElectionScreen({super.key});
  @override
  ConsumerState<ElectionScreen> createState() => _ElectionScreenState();
}

/// Health intents are listed but never searched (owner decision 19).
const _health = 'surgery';

class _ElectionScreenState extends ConsumerState<ElectionScreen> {
  String _intent = ElectionIntent.contract.id;
  String? _profileId;
  bool _personal = false;
  DateTime _start = DateTime.now();
  int _days = 30;
  RangeValues _hours = const RangeValues(0, 24);
  final Set<int> _weekdays = {1, 2, 3, 4, 5, 6, 7};
  Future<ElectionResult>? _result;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final content = ref.watch(contentProvider).value;
    final profiles = ref.watch(profilesProvider).value ?? const <Profile>[];
    final profile = profiles.where((p) => p.id == _profileId).firstOrNull ?? profiles.firstOrNull;
    final health = _intent == _health;
    return Scaffold(
      appBar: AppBar(title: Text(l.electionTitle)),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        DropdownButtonFormField<String>(
          isExpanded: true,
          initialValue: _intent,
          decoration: InputDecoration(labelText: l.electionIntent),
          items: [
            for (final id in [...ElectionIntent.values.map((i) => i.id), ...electionHealthIntentIds])
              DropdownMenuItem(value: id, child: Text(l.electionIntentName(id), overflow: TextOverflow.ellipsis)),
          ],
          onChanged: (v) => setState(() {
            _intent = v ?? _intent;
            _result = null;
          }),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: () => health
                ? showEntry(context, content?['glossary/medical_election'], title: l.electionIntentName(_intent))
                : showEntry(context, content?['election/intent/$_intent'], title: l.electionIntentName(_intent)),
            child: Text(l.electionAboutIntent),
          ),
        ),
        if (health) ...[
          Text(l.electionHealthNote, style: t.bodyMedium),
          EntryView(content?['election/verdict/health'], fallbackTitle: l.electionVerdict('health')),
          EntryView(content?['glossary/medical_election'], fallbackTitle: l.electionIntentName(_health)),
        ] else if (profile == null)
          Padding(padding: const EdgeInsets.all(16), child: Text(l.electionNeedsProfile))
        else
          ..._form(context, profile),
      ]),
    );
  }

  List<Widget> _form(BuildContext context, Profile profile) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final profiles = ref.watch(profilesProvider).value ?? const <Profile>[];
    final place = profile.residencePlace;
    return [
      DropdownButtonFormField<String>(
        isExpanded: true,
        initialValue: profile.id,
        decoration: InputDecoration(labelText: l.electionProfile),
        items: [for (final p in profiles) DropdownMenuItem(value: p.id, child: Text(p.name, overflow: TextOverflow.ellipsis))],
        onChanged: (v) => setState(() {
          _profileId = v;
          _result = null;
        }),
      ),
      Padding(padding: const EdgeInsets.only(top: 4), child: Text(l.electionPlace(place.name ?? '${place.lat}, ${place.lon}'), style: t.bodySmall)),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(l.electionPersonal),
        subtitle: Text(l.electionPersonalHint),
        value: _personal,
        onChanged: (v) => setState(() => _personal = v),
      ),
      Row(children: [
        Expanded(child: Text('${l.electionStart} ${fmtDate(_start)}')),
        TextButton(
          onPressed: () async {
            final now = DateTime.now();
            final d = await showDatePicker(context: context, initialDate: _start, firstDate: DateTime(now.year - 1), lastDate: DateTime(now.year + 10));
            if (d != null) setState(() => _start = d);
          },
          child: Text(l.pickDate),
        ),
      ]),
      Text(l.electionDays(_days)),
      Slider(
        value: _days.toDouble(),
        min: 1,
        max: ElectionQuery.maxDays.toDouble(),
        divisions: ElectionQuery.maxDays - 1,
        label: '$_days',
        onChanged: (v) => setState(() => _days = v.round()),
      ),
      Text(l.electionHours(_hours.start.round(), _hours.end.round())),
      RangeSlider(
        values: _hours,
        min: 0,
        max: 24,
        divisions: 24,
        onChanged: (v) => setState(() => _hours = v.end - v.start < 1 ? _hours : v),
      ),
      Text(l.electionWeekdays),
      Wrap(spacing: 4, children: [
        for (var d = 1; d <= 7; d++)
          FilterChip(
            label: Text(l.weekdayShort('$d')),
            selected: _weekdays.contains(d),
            onSelected: (on) => setState(() => on ? _weekdays.add(d) : (_weekdays.length > 1 ? _weekdays.remove(d) : null)),
          ),
      ]),
      const SizedBox(height: 12),
      FilledButton.icon(
        icon: const Icon(Icons.search),
        label: Text(l.electionSearch),
        onPressed: () => _run(profile),
      ),
      const SizedBox(height: 8),
      Text(l.electionDisclaimer, style: t.bodySmall),
      const SizedBox(height: 12),
      if (_result != null)
        FutureBuilder<ElectionResult>(
          future: _result,
          builder: (context, snap) {
            if (!snap.hasData) return Text(snap.hasError ? '${snap.error}' : l.computing);
            return _Results(snap.data!, l.electionIntentName(_intent));
          },
        ),
    ];
  }

  Future<void> _run(Profile profile) async {
    final book = await ref.read(electionRulesProvider.future);
    final from = _hours.start.round(), to = _hours.end.round();
    final q = ElectionQuery(
      intent: ElectionIntent.values.byName(_intent),
      year: _start.year,
      month: _start.month,
      day: _start.day,
      days: _days,
      place: profile.residencePlace,
      natal: _personal ? ref.read(chartProvider(profile)) : null,
      hours: from == 0 && to == 24 ? null : {for (var h = from; h < to; h++) h},
      weekdays: _weekdays.length == 7 ? null : {..._weekdays},
    );
    setState(() => _result = searchElection(q, book));
  }
}

class _Results extends ConsumerWidget {
  final ElectionResult result;
  final String intentName;
  const _Results(this.result, this.intentName);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final content = ref.watch(contentProvider).value;
    final place = result.query.place;
    IcsEvent ics(ElectionWindow w) => IcsEvent(
          w.start,
          w.end,
          l.electionEventTitle(intentName),
          '${l.electionVerdict(w.verdict)} · ${l.electionScore(w.score)}\n'
          '${l.electionFor}: ${w.plus.map((r) => l.electionRule(r.id)).join(', ')}\n'
          '${l.electionAgainst}: ${w.minus.map((r) => l.electionRule(r.id)).join(', ')}\n'
          '${l.electionDisclaimer}',
        );
    final passed = result.anyPassed;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(passed ? l.electionFound : l.electionNonePassed, style: t.titleMedium),
      if (!passed) EntryView(content?['election/verdict/none'], showTitle: false),
      if (passed && result.windows.length > 1)
        TextButton.icon(
          icon: const Icon(Icons.event),
          label: Text(l.electionCalendarAll),
          onPressed: () => shareIcs([for (final w in result.windows) ics(w)], l.electionTitle),
        ),
      for (final w in result.windows) _WindowCard(w, place, onCalendar: () => shareIcs([ics(w)], l.electionTitle)),
    ]);
  }
}

class _WindowCard extends ConsumerWidget {
  final ElectionWindow w;
  final GeoLocation place;
  final VoidCallback onCalendar;
  const _WindowCard(this.w, this.place, {required this.onCalendar});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final content = ref.watch(contentProvider).value;
    final a = localTime(w.start, place), b = localTime(w.end, place);
    Widget column(String title, List<Rule> rules) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: t.labelLarge),
          if (rules.isEmpty) const Text('—'),
          for (final r in rules)
            InkWell(
              onTap: () => showEntry(context, content?[r.textKey], title: l.electionRule(r.id)),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Text('${l.electionRule(r.id)} (${r.points > 0 ? '+' : ''}${r.points})', style: t.bodySmall),
              ),
            ),
        ]);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          InkWell(
            onTap: () => showEntry(context, content?['election/verdict/${w.verdict}'], title: l.electionVerdict(w.verdict)),
            child: Text('${fmtDate(a)} · ${fmtTime(a)}–${fmtTime(b)}', style: t.titleMedium),
          ),
          Text('${l.electionVerdict(w.verdict)} · ${l.electionScore(w.score)}', style: t.bodySmall),
          const SizedBox(height: 8),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: column(l.electionFor, w.plus)),
            const SizedBox(width: 12),
            Expanded(child: column(l.electionAgainst, w.minus)),
          ]),
          Wrap(spacing: 8, children: [
            TextButton.icon(
              icon: const Icon(Icons.blur_circular),
              label: Text(l.electionOpenChart),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ChartScreen(momentProfile(w.start, place, l.electionMomentName(fmtDateTime(a))))),
              ),
            ),
            TextButton.icon(icon: const Icon(Icons.event), label: Text(l.electionCalendar), onPressed: onCalendar),
            // TODO(R3): "save as hypothesis" once the journal is in main.
          ]),
        ]),
      ),
    );
  }
}
