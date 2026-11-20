import 'package:astro_core/astro_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/profile.dart';
import '../../export/horary_pdf.dart';
import '../../l10n/app_localizations.dart';
import '../../logic/election.dart' show momentProfile;
import '../../logic/horary.dart';
import '../../state.dart';
import '../chart/chart_screen.dart';
import '../entry_view.dart';
import '../format.dart';

/// "Zeptej se" horary mode (plan 10.8): question text for the user only, topic
/// from the closed list, whom it is about, the moment of confirmation and the
/// residence of the profile.
class HoraryPanel extends ConsumerStatefulWidget {
  final Profile profile;
  const HoraryPanel(this.profile, {super.key});
  @override
  ConsumerState<HoraryPanel> createState() => _HoraryPanelState();
}

class _HoraryPanelState extends ConsumerState<HoraryPanel> {
  final _text = TextEditingController();
  String _topic = 'career';
  String _person = 'self';
  bool _busy = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _ask() async {
    final l = AppLocalizations.of(context);
    final profile = widget.profile;
    final book = await ref.read(horaryBookProvider.future);
    final log = await ref.read(horaryLogProvider(profile.id).future);
    final now = HoraryLogNotifier.clock();
    final first = log.repeatOf(_topic, _person, now);
    if (!mounted) return;
    if (first != null) {
      final show = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: Text(l.horaryRepeatTitle),
          content: Text(l.horaryRepeatBody(fmtDateTime(first.createdAt.toLocal()))),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: Text(l.cancel)),
            FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(l.horaryShowFirst)),
          ],
        ),
      );
      if (show == true && mounted) {
        await Navigator.push(context, MaterialPageRoute(builder: (_) => HoraryResultScreen(profile, first)));
      }
      return;
    }
    setState(() => _busy = true);
    try {
      final q = HoraryQuestion(jdUt: jdFromDateTimeUtc(now.toUtc()), place: profile.residencePlace, topic: _topic, person: _person);
      final j = await judgeHorary(q, book);
      final r = await ref.read(horaryLogProvider(profile.id).notifier).addQuestion(_text.text, j);
      if (!mounted) return;
      _text.clear();
      await Navigator.push(context, MaterialPageRoute(builder: (_) => HoraryResultScreen(profile, r, judgement: j)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final book = ref.watch(horaryBookProvider).value;
    final content = ref.watch(contentProvider).value;
    final place = widget.profile.residencePlace;
    final topic = book?.topics.where((x) => x.id == _topic).firstOrNull;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(l.horaryIntro, style: t.bodyMedium),
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton(onPressed: () => showEntry(context, content?['glossary/horary'], title: l.horaryAbout), child: Text(l.horaryAbout)),
      ),
      TextField(
        controller: _text,
        maxLines: 3,
        minLines: 1,
        decoration: InputDecoration(labelText: l.horaryQuestion, helperText: l.horaryQuestionHint, helperMaxLines: 2),
      ),
      const SizedBox(height: 12),
      DropdownButtonFormField<String>(
        isExpanded: true,
        initialValue: _topic,
        decoration: InputDecoration(labelText: l.horaryTopic),
        items: [
          for (final tp in book?.topics ?? const <HoraryTopic>[])
            DropdownMenuItem(value: tp.id, child: Text(l.horaryTopicName(tp.id), overflow: TextOverflow.ellipsis)),
        ],
        onChanged: (v) => setState(() => _topic = v ?? _topic),
      ),
      const SizedBox(height: 12),
      DropdownButtonFormField<String>(
        isExpanded: true,
        initialValue: _person,
        decoration: InputDecoration(labelText: l.horaryPerson),
        items: [
          for (final p in book?.persons ?? const <HoraryPerson>[])
            DropdownMenuItem(value: p.id, child: Text(l.horaryPersonName(p.id), overflow: TextOverflow.ellipsis)),
        ],
        onChanged: (v) => setState(() => _person = v ?? _person),
      ),
      if (topic != null && book != null)
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(l.horaryHouseUsed(derivedHouse(book.person(_person).house, topic.house)), style: t.bodySmall),
        ),
      Padding(padding: const EdgeInsets.only(top: 4), child: Text(l.electionPlace(place.name ?? '${place.lat}, ${place.lon}'), style: t.bodySmall)),
      if (topic?.noVerdict ?? false) Padding(padding: const EdgeInsets.only(top: 8), child: Text(l.horaryNoVerdict, style: t.bodyMedium)),
      const SizedBox(height: 12),
      FilledButton.icon(
        icon: const Icon(Icons.help_outline),
        label: Text(_busy ? l.computing : l.horaryAsk),
        onPressed: _busy || book == null ? null : _ask,
      ),
      const SizedBox(height: 4),
      Text(l.horaryMomentNote, style: t.bodySmall),
      const SizedBox(height: 8),
      OutlinedButton.icon(
        icon: const Icon(Icons.history),
        label: Text(l.horaryLogTitle),
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => HoraryLogScreen(widget.profile))),
      ),
    ]);
  }
}

/// Verdict with reasons for and against, considerations, timing, lost object.
class HoraryResultScreen extends ConsumerStatefulWidget {
  final Profile profile;
  final HoraryRecord record;
  final HoraryJudgement? judgement;
  const HoraryResultScreen(this.profile, this.record, {this.judgement, super.key});
  @override
  ConsumerState<HoraryResultScreen> createState() => _HoraryResultScreenState();
}

class _HoraryResultScreenState extends ConsumerState<HoraryResultScreen> {
  late final Future<HoraryJudgement> _j = widget.judgement != null
      ? Future.value(widget.judgement)
      : ref.read(horaryBookProvider.future).then((b) => judgeHorary(questionOf(widget.record), b));

  Future<void> _pdf(HoraryJudgement j) async {
    final l = AppLocalizations.of(context);
    var withText = false;
    final go = await showDialog<bool>(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, set) => AlertDialog(
          title: Text(l.horaryPdfTitle),
          content: CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: withText,
            title: Text(l.horaryPdfIncludeText),
            onChanged: (v) => set(() => withText = v ?? false),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: Text(l.cancel)),
            FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(l.horaryPdf)),
          ],
        ),
      ),
    );
    if (go != true || !mounted) return;
    final content = await ref.read(contentProvider.future);
    if (!mounted) return;
    await shareHoraryPdf(l, widget.record, j, content, includeText: withText);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return FutureBuilder<HoraryJudgement>(
      future: _j,
      builder: (context, snap) => Scaffold(
        appBar: AppBar(title: Text(l.horaryTopicName(widget.record.topic ?? '')), actions: [
          if (snap.hasData) IconButton(tooltip: l.horaryPdf, icon: const Icon(Icons.picture_as_pdf_outlined), onPressed: () => _pdf(snap.data!)),
        ]),
        body: !snap.hasData
            ? Center(child: Text(snap.hasError ? '${snap.error}' : l.computing))
            : HoraryResultView(widget.profile, widget.record, snap.data!),
      ),
    );
  }
}

class HoraryResultView extends ConsumerWidget {
  final Profile profile;
  final HoraryRecord record;
  final HoraryJudgement j;
  const HoraryResultView(this.profile, this.record, this.j, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final content = ref.watch(contentProvider).value;
    final place = j.question.place;
    final when = localTime(j.question.jdUt, place);
    final f = j.facts;
    Widget column(String title, List<Rule> rules) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: t.labelLarge),
          if (rules.isEmpty) const Text('—'),
          for (final r in rules)
            InkWell(
              onTap: () => showEntry(context, content?[r.textKey], title: l.horaryTestimony(r.id)),
              child: Padding(padding: const EdgeInsets.symmetric(vertical: 3), child: Text(l.horaryTestimony(r.id), style: t.bodySmall)),
            ),
        ]);
    Widget section(String title) => Padding(padding: const EdgeInsets.only(top: 20, bottom: 4), child: Text(title, style: t.titleMedium));
    String sig(Body b) {
      final s = f!.strength[b]!;
      return '${l.body(b)} · ${lonLabel(l, j.chart[b].lon)} · ${l.horaryHouseShort(j.chart[b].house)} · ${l.horaryStrength(s.total, s.essential, s.accidental)}';
    }

    final text = record.text ?? '';
    return ListView(padding: const EdgeInsets.all(16), children: [
      if (text.isNotEmpty) Text('„$text“', style: t.bodyLarge?.copyWith(fontStyle: FontStyle.italic)),
      Text(l.horaryMoment(fmtDateTime(when), place.name ?? '${place.lat}, ${place.lon}'), style: t.bodySmall),
      const SizedBox(height: 12),
      if (j.noVerdict) ...[
        Text(l.horaryNoVerdict, style: t.titleMedium),
        EntryView(content?['glossary/medical_horary'], fallbackTitle: l.horaryAboutHealth),
      ] else ...[
        InkWell(
          onTap: () => showEntry(context, content?['horary/verdict/${j.verdict!.id}'], title: l.horaryVerdictName(j.verdict!.id)),
          child: Text(l.horaryVerdictLine(l.horaryVerdictName(j.verdict!.id)), style: t.headlineSmall),
        ),
        Text(l.horaryDisclaimer, style: t.bodySmall),
        const SizedBox(height: 12),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: column(l.electionFor, j.plus)),
          const SizedBox(width: 12),
          Expanded(child: column(l.electionAgainst, j.minus)),
        ]),
        if (j.timing != null) ...[
          section(l.horaryTimingTitle),
          InkWell(
            onTap: () => showEntry(context, content?['horary/timing/${j.timing!.unit}'], title: l.horaryTimingTitle),
            child: Text(_timing(l, j.timing!)),
          ),
        ],
        if (j.lost != null) ...[
          section(l.horaryLostTitle),
          Text(l.horaryLostLine(l.horaryDirection(j.lost!.bySign), l.sign(j.lost!.sign), l.horaryDirection(j.lost!.byHouse), j.lost!.house)),
          EntryView(content?['horary/lost/${j.lost!.sign.name}'], fallbackTitle: l.sign(j.lost!.sign)),
          EntryView(content?['horary/lost_house/${j.lost!.house}'], fallbackTitle: l.horaryHouseShort(j.lost!.house)),
        ],
        if (f != null) ...[
          section(l.horarySignificators),
          ListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: Text(l.horaryQuerent(f.person.house)),
            subtitle: Text(sig(f.querent)),
            onTap: () => showEntry(context, content?['horary/significator/${f.querent.name}'], title: l.body(f.querent)),
          ),
          if (f.coQuerent != null)
            ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: Text(l.horaryCoQuerent),
              subtitle: Text(sig(Body.moon)),
              onTap: () => showEntry(context, content?['horary/significator/moon'], title: l.body(Body.moon)),
            ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: Text(l.horaryQuesited(f.quesitedHouse)),
            subtitle: Text(sig(f.quesited)),
            onTap: () => showEntry(context, content?['horary/house/${f.quesitedHouse}'], title: l.horaryHouseShort(f.quesitedHouse)),
          ),
          if (f.natural != null)
            ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: Text(l.horaryNatural),
              subtitle: Text(sig(f.natural!)),
              onTap: () => showEntry(context, content?['horary/significator/${f.natural!.name}'], title: l.body(f.natural!)),
            ),
        ],
      ],
      section(l.horaryConsiderations),
      Text(l.horaryConsiderationNote, style: t.bodySmall),
      if (j.considerations.isEmpty) Text(l.horaryConsiderationsNone),
      for (final c in j.considerations)
        ListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          leading: const Icon(Icons.warning_amber_outlined),
          title: Text(l.horaryConsideration(c.id)),
          onTap: () => showEntry(context, content?[c.textKey], title: l.horaryConsideration(c.id)),
        ),
      const SizedBox(height: 12),
      Wrap(spacing: 8, children: [
        TextButton.icon(
          icon: const Icon(Icons.blur_circular),
          label: Text(l.electionOpenChart),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChartScreen(
                momentProfile(j.question.jdUt, place, l.electionMomentName(fmtDateTime(when))).copyWith(houseSystem: j.chart.houses.system),
              ),
            ),
          ),
        ),
      ]),
    ]);
  }
}

String _timing(AppLocalizations l, HoraryTiming tm) {
  final n = tm.count;
  final unit = switch (tm.unit) {
    'days' => l.horaryDays(n),
    'weeks' => l.horaryWeeks(n),
    'months' => l.horaryMonths(n),
    'years' => l.horaryYears(n),
    _ => null,
  };
  return unit == null ? l.horaryTimingUnknown : l.horaryTimingLine(tm.degrees.toStringAsFixed(1), unit);
}

/// Text of the timing estimate (also used by the PDF).
String horaryTimingText(AppLocalizations l, HoraryTiming tm) => _timing(l, tm);

/// The question log: verdicts, "how did it turn out?", hit rate vs baselines.
class HoraryLogScreen extends ConsumerWidget {
  final Profile profile;
  const HoraryLogScreen(this.profile, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final log = ref.watch(horaryLogProvider(profile.id));
    return Scaffold(
      appBar: AppBar(title: Text(l.horaryLogTitle)),
      body: log.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(padding: const EdgeInsets.all(32), child: Text(e is HoraryLogSchemaError ? l.journalErrorNewer : '$e', textAlign: TextAlign.center)),
        ),
        data: (log) {
          final now = HoraryLogNotifier.clock();
          final due = {for (final q in log.dueFollowUps(now)) q.id};
          final hr = log.hitRate();
          final closed = log.questions.where((q) => log.outcomeOf(q.id) != null).length;
          return ListView(padding: const EdgeInsets.all(16), children: [
            Text(
              hr == null
                  ? l.horaryHitRateTooFew(HoraryLog.minForHitRate, closed)
                  : l.horaryHitRate((hr.rate * 100).round(), hr.n, (hr.yesRate * 100).round(), (hr.noRate * 100).round()),
              style: t.bodyMedium,
            ),
            const SizedBox(height: 12),
            if (log.questions.isEmpty) Text(l.horaryLogEmpty),
            for (final q in log.questions)
              Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    InkWell(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => HoraryResultScreen(profile, q))),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('${fmtDateTime(q.createdAt.toLocal())} · ${l.horaryTopicName(q.topic ?? '')}', style: t.titleSmall),
                        if ((q.text ?? '').isNotEmpty) Text(q.text!, style: t.bodyMedium),
                        Text(q.verdict == null ? l.horaryNoVerdictShort : l.horaryVerdictName(q.verdict!), style: t.bodySmall),
                      ]),
                    ),
                    if (log.outcomeOf(q.id) case final o?)
                      Text(l.horaryOutcomeSet(l.horaryOutcomeName(o.name)), style: t.bodySmall)
                    else if (due.contains(q.id)) ...[
                      const SizedBox(height: 6),
                      Text(l.horaryFollowUp, style: t.labelLarge),
                      Wrap(spacing: 8, children: [
                        for (final o in HoraryOutcome.values)
                          OutlinedButton(
                            onPressed: () => ref.read(horaryLogProvider(profile.id).notifier).setOutcome(q.id, o),
                            child: Text(l.horaryOutcomeName(o.name)),
                          ),
                      ]),
                    ],
                  ]),
                ),
              ),
          ]);
        },
      ),
    );
  }
}
