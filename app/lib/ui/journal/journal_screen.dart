import 'dart:convert';

import 'package:astro_core/astro_core.dart';
import 'package:astro_core/content.dart';
import 'package:astro_core/journal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/content_repository.dart';
import '../../data/profile.dart';
import '../../journal_state.dart';
import '../../l10n/app_localizations.dart';
import '../../logic/journal_compute.dart';
import '../../state.dart';
import '../entry_view.dart';
import '../format.dart';
import '../people_screen.dart' show Person, peopleProvider;
import 'journal_format.dart';
import 'rating_sheet.dart';
import '../../platform/share_bytes.dart';

/// Prediction journal of one profile (plan 10.3).
class JournalScreen extends ConsumerWidget {
  final Profile profile;
  final Chart chart;
  const JournalScreen(this.profile, this.chart, {super.key});

  Future<void> _export(BuildContext context, Journal j) async {
    final subject = AppLocalizations.of(context).journalTitle;
    await shareBytes(utf8.encode(journalCsv(j)), 'denik-${profile.id}.csv', 'text/csv', subject: subject);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final journal = ref.watch(journalProvider(profile.id));
    return Scaffold(
      appBar: AppBar(
        title: Text(l.journalTitle),
        actions: [
          if (journal.value != null)
            IconButton(tooltip: l.journalExport, icon: const Icon(Icons.file_download_outlined), onPressed: () => _export(context, journal.value!)),
        ],
      ),
      body: journal.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(padding: const EdgeInsets.all(32), child: Text(e is JournalSchemaError ? l.journalErrorNewer : '$e', textAlign: TextAlign.center)),
        ),
        data: (j) => _JournalBody(profile, chart, j),
      ),
    );
  }
}

class _JournalBody extends ConsumerWidget {
  final Profile profile;
  final Chart chart;
  final Journal journal;
  const _JournalBody(this.profile, this.chart, this.journal);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final content = ref.watch(contentProvider).value ?? const ContentRepository({}, []);
    final now = JournalNotifier.clock();
    final today = dayNumberOf(now);
    final todayKey = dayKeyOf(today), yesterdayKey = dayKeyOf(today - 1);
    final log = journal.log;
    final blind = journal.blindOn(today);
    final days = [...log.subjects]..sort((a, b) => b.compareTo(a));

    Widget section(String title) => Padding(padding: const EdgeInsets.fromLTRB(16, 20, 16, 4), child: Text(title, style: t.titleMedium));

    return ListView(padding: const EdgeInsets.only(bottom: 32), children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Wrap(spacing: 8, runSpacing: 8, children: [
          FilledButton.icon(
            icon: const Icon(Icons.edit_note),
            label: Text(log.original(todayKey) == null ? l.journalRateToday : l.journalChangeRating),
            onPressed: () => showRatingSheet(context, profile, chart, todayKey, initial: log.original(todayKey)),
          ),
          if (log.original(yesterdayKey) == null)
            OutlinedButton(onPressed: () => showRatingSheet(context, profile, chart, yesterdayKey), child: Text(l.journalRateYesterday)),
        ]),
      ),
      // Blind test (owner decision 16: voluntary, off by default).
      SwitchListTile(
        title: Text(l.journalBlindTitle),
        subtitle: Text(blind == null ? l.journalBlindOff : l.journalBlindRunning(fmtDay(dayKeyOf(blind.lastDay)))),
        value: blind != null,
        onChanged: (on) async {
          if (!on) {
            final ok = await showDialog<bool>(
              context: context,
              builder: (c) => AlertDialog(content: Text(l.journalBlindStopConfirm), actions: [
                TextButton(onPressed: () => Navigator.pop(c, false), child: Text(l.cancel)),
                TextButton(onPressed: () => Navigator.pop(c, true), child: Text(l.ok)),
              ]),
            );
            if (ok != true) return;
          }
          await ref.read(journalProvider(profile.id).notifier).setBlind(on);
        },
      ),
      section(l.journalEvaluation),
      _Evaluation(profile, chart, journal, content),
      section(l.journalHypotheses),
      _Hypotheses(profile, chart, journal, content),
      section(l.journalHistory),
      if (days.isEmpty) Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text(l.journalEmpty)),
      for (final d in days) _DayTile(profile, chart, journal, d, content),
      const Divider(height: 32),
      ExpansionTile(title: Text(l.journalMethod), children: [
        Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: JournalText(content, 'method')),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: JournalText(content, 'blind')),
      ]),
    ]);
  }
}

/// A `journal/…` text, or "Text zatím chybí".
class JournalText extends StatelessWidget {
  final ContentRepository content;
  final String id;
  const JournalText(this.content, this.id, {super.key});

  @override
  Widget build(BuildContext context) {
    final e = content['journal/$id'];
    if (e == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(AppLocalizations.of(context).journalTextMissing, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic)),
      );
    }
    return EntryView(e);
  }
}

class _DayTile extends StatelessWidget {
  final Profile profile;
  final Chart chart;
  final Journal journal;
  final String day;
  final ContentRepository content;
  const _DayTile(this.profile, this.chart, this.journal, this.day, this.content);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final log = journal.log;
    final original = log.original(day)!;
    final current = log.current(day)!;
    final open = log.isOpen(day, JournalNotifier.clock());
    String tagName(String id) => content.trait(id)?.name ?? id;
    final flags = [
      original.sawPrediction ? l.journalSawPrediction : l.journalBlindFlag,
      l.journalTension(fmtNum(original.tension, 0)),
      if (current.corrects != null) l.journalCorrectionOf(ratingLabel(l, original.rating)),
    ];
    return ListTile(
      title: Text('${fmtDay(day)} · ${ratingLabel(l, current.rating)}'),
      subtitle: Text([
        flags.join(' · '),
        if (current.tags.isNotEmpty) current.tags.map(tagName).join(', '),
        if (current.note.isNotEmpty) current.note,
      ].join('\n')),
      isThreeLine: current.tags.isNotEmpty || current.note.isNotEmpty,
      trailing: Icon(open ? Icons.edit_outlined : Icons.lock_outline, size: 18),
      onTap: () => open
          ? showRatingSheet(context, profile, chart, day, initial: original)
          : showRatingSheet(context, profile, chart, day, initial: current, corrects: original.id),
    );
  }
}

class _Evaluation extends ConsumerStatefulWidget {
  final Profile profile;
  final Chart chart;
  final Journal journal;
  final ContentRepository content;
  const _Evaluation(this.profile, this.chart, this.journal, this.content);
  @override
  ConsumerState<_Evaluation> createState() => _EvaluationState();
}

class _EvaluationState extends ConsumerState<_Evaluation> {
  Future<JournalReport>? _report;
  Object? _key;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final people = ref.watch(peopleProvider);
    if (!people.hasValue && !people.hasError) return Center(child: Text(l.computing));
    final catalog = [
      for (final p in people.value ?? const <Person>[])
        if (p.id != widget.profile.catalogId) p.profile.birth
    ];
    final key = (widget.journal, widget.chart, catalog.length);
    if (_report == null || _key != key) {
      _key = key;
      _report = computeJournalReport(widget.chart, widget.journal, catalog);
    }
    return FutureBuilder<JournalReport>(
      future: _report,
      builder: (context, snap) {
        if (!snap.hasData) return Padding(padding: const EdgeInsets.all(16), child: Text(snap.hasError ? '${snap.error}' : l.computing));
        final r = snap.data!;
        final blindUsed = widget.journal.blindTests.isNotEmpty || r.evaluation.blind.result.n > 0;
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (blindUsed) _GroupCard(l.journalGroupBlind, r.evaluation.blind, r.catalogSize, widget.content),
          _GroupCard(l.journalGroupSeen, r.evaluation.seen, r.catalogSize, widget.content),
          if (r.hypotheses.isNotEmpty) _HypothesisResults(r.hypotheses, widget.content),
        ]);
      },
    );
  }
}

/// One evaluated group. "No relation" uses the same card and type size as a relation (plan 10.3).
class _GroupCard extends StatelessWidget {
  final String title;
  final GroupEvaluation g;
  final int catalogSize;
  final ContentRepository content;
  const _GroupCard(this.title, this.g, this.catalogSize, this.content);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final r = g.result;
    final children = <Widget>[Text(title, style: t.labelLarge)];
    switch (r.relation) {
      case Relation.tooFew:
        children
          ..add(Text(l.journalTooFew(r.n, minEvaluatedDays), style: t.titleMedium))
          ..add(JournalText(content, 'too_few'));
      case Relation.undefined:
        children.add(Text(l.journalUndefined, style: t.titleMedium));
      case Relation.expected || Relation.opposite || Relation.none:
        final test = r.test!;
        final headline = switch (r.relation) {
          Relation.expected => l.journalResultExpected,
          Relation.opposite => l.journalResultOpposite,
          _ => l.journalResultNone,
        };
        children
          ..add(Text(headline, style: t.titleMedium))
          ..add(Text(l.journalResultNumbers(
            fmtNum(test.rho),
            l.journalEffect(r.size!.name),
            fmtShare(r.p!, permutations: test.permutations),
            '${test.permutations}',
            '${r.n}',
            '${test.blocks}',
          )))
          ..add(JournalText(content, switch (r.relation) {
            Relation.expected => 'relation_expected',
            Relation.opposite => 'relation_opposite',
            _ => 'no_relation',
          }));
        children.add(const SizedBox(height: 8));
        children.add(Text(l.journalControl, style: t.labelLarge));
        final c = g.control;
        if (c == null || !c.enough) {
          children.add(Text(l.journalControlFew(catalogSize, minControlPersons)));
        } else {
          children
            ..add(Text(c.ownFitsBetter ? l.journalControlBetter : l.journalControlNotBetter, style: t.titleSmall))
            ..add(Text(l.journalControlResult('${c.persons}', '${c.asGoodOrBetter}', fmtNum(c.ownRho), fmtNum(c.median))));
          if (c.persons < controlPersons) children.add(Text(l.journalControlPartial(c.persons, controlPersons), style: t.bodySmall));
          children.add(JournalText(content, c.ownFitsBetter ? 'control_better' : 'control_not_better'));
        }
    }
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 4, children: children)),
    );
  }
}

class _HypothesisResults extends StatelessWidget {
  final List<HypothesisResult> results;
  final ContentRepository content;
  const _HypothesisResults(this.results, this.content);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    return Column(children: [
      for (final r in results)
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 4, children: [
              Text(hypothesisTitle(l, r.hypothesis, content), style: t.labelLarge),
              if (!r.enough) ...[
                Text(l.journalHypothesisFew(minHypothesisDays), style: t.titleMedium),
              ] else ...[
                Text(r.holds ? l.journalHypothesisMore(fmtNum(r.p!, 3)) : l.journalHypothesisNotMore(fmtNum(r.p!, 3)), style: t.titleMedium),
                JournalText(content, r.holds ? 'hypothesis_more' : 'hypothesis_not_more'),
              ],
              Text(l.journalHypothesisResult(
                '${r.transitTagged}', '${r.transitDays}', fmtShare(r.transitRate),
                '${r.otherTagged}', '${r.otherDays}', fmtShare(r.baseRate),
              )),
            ]),
          ),
        ),
    ]);
  }
}

String hypothesisTitle(AppLocalizations l, Hypothesis h, ContentRepository content) => l.journalHypothesisRule(
      l.transitTitle(l.body(h.transiting), l.aspect(h.type), l.point(h.target)),
      content.trait(h.tag)?.name ?? h.tag,
    );

class _Hypotheses extends ConsumerWidget {
  final Profile profile;
  final Chart chart;
  final Journal journal;
  final ContentRepository content;
  const _Hypotheses(this.profile, this.chart, this.journal, this.content);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      for (final h in journal.hypotheses)
        ListTile(
          dense: true,
          title: Text(hypothesisTitle(l, h, content)),
          subtitle: Text(l.journalHypothesisSince(fmtDay(h.createdDay))),
          trailing: IconButton(
            tooltip: l.journalHypothesisDelete,
            icon: const Icon(Icons.delete_outline),
            onPressed: () => ref.read(journalProvider(profile.id).notifier).removeHypothesis(h.id),
          ),
        ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: OutlinedButton.icon(
          icon: const Icon(Icons.add),
          label: Text(l.journalHypothesisAdd),
          onPressed: () => showDialog<void>(context: context, builder: (_) => HypothesisForm(profile, chart)),
        ),
      ),
    ]);
  }
}

class HypothesisForm extends ConsumerStatefulWidget {
  final Profile profile;
  final Chart chart;
  const HypothesisForm(this.profile, this.chart, {super.key});
  @override
  ConsumerState<HypothesisForm> createState() => _HypothesisFormState();
}

class _HypothesisFormState extends ConsumerState<HypothesisForm> {
  Body _body = Body.mars;
  AspectType _type = AspectType.square;
  ChartPoint _target = const ChartPoint.body(Body.moon);
  Trait? _tag;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final traits = ref.watch(contentProvider).value?.traits ?? const <Trait>[];
    final targets = TransitEngine(widget.chart).targets;
    return AlertDialog(
      title: Text(l.journalHypothesisAdd),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          DropdownButtonFormField<Body>(
            initialValue: _body,
            decoration: InputDecoration(labelText: l.journalHypothesisTransiting),
            items: [for (final b in Body.planets) DropdownMenuItem(value: b, child: Text(l.body(b)))],
            onChanged: (v) => setState(() => _body = v!),
          ),
          DropdownButtonFormField<AspectType>(
            initialValue: _type,
            decoration: InputDecoration(labelText: l.journalHypothesisAspect),
            items: [for (final a in AspectType.major) DropdownMenuItem(value: a, child: Text(l.aspect(a)))],
            onChanged: (v) => setState(() => _type = v!),
          ),
          DropdownButtonFormField<ChartPoint>(
            initialValue: targets.contains(_target) ? _target : targets.first,
            decoration: InputDecoration(labelText: l.journalHypothesisTarget),
            items: [for (final p in targets) DropdownMenuItem(value: p, child: Text(l.point(p)))],
            onChanged: (v) => setState(() => _target = v!),
          ),
          DropdownButtonFormField<Trait>(
            initialValue: _tag,
            isExpanded: true,
            decoration: InputDecoration(labelText: l.journalHypothesisTag),
            items: [for (final x in [...traits]..sort((a, b) => a.name.compareTo(b.name))) DropdownMenuItem(value: x, child: Text(x.name))],
            onChanged: (v) => setState(() => _tag = v),
          ),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l.cancel)),
        FilledButton(
          onPressed: _tag == null
              ? null
              : () async {
                  final now = JournalNotifier.clock();
                  await ref.read(journalProvider(widget.profile.id).notifier).addHypothesis(Hypothesis(
                        id: 'h${now.microsecondsSinceEpoch}',
                        createdDay: dayKeyOf(dayNumberOf(now)),
                        transiting: _body,
                        type: _type,
                        target: targets.contains(_target) ? _target : targets.first,
                        tag: _tag!.id,
                      ));
                  if (context.mounted) Navigator.pop(context);
                },
          child: Text(l.journalSave),
        ),
      ],
    );
  }
}

/// Blind test: the transits tab stays locked until today is rated (plan 10.3).
class BlindGate extends ConsumerWidget {
  final Profile profile;
  final Chart chart;
  final Widget child;
  const BlindGate(this.profile, this.chart, {super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (profile.catalogId != null) return child;
    final j = ref.watch(journalProvider(profile.id)).value;
    final now = JournalNotifier.clock();
    if (j == null || !j.transitsLocked(now)) return child;
    final l = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, spacing: 16, children: [
          const Icon(Icons.visibility_off_outlined, size: 40),
          Text(l.journalBlindLocked, textAlign: TextAlign.center),
          FilledButton(
            onPressed: () => showRatingSheet(context, profile, chart, dayKeyOf(dayNumberOf(now))),
            child: Text(l.journalRateToday),
          ),
        ]),
      ),
    );
  }
}
