import 'package:astro_core/astro_core.dart';
import 'package:astro_core/content.dart';
import 'package:flutter/material.dart';

import '../../data/content_repository.dart';
import '../../l10n/app_localizations.dart';
import '../entry_view.dart';
import '../format.dart';
import 'pair_names.dart';

enum PeriodFilter { strain, support, all }

/// "Období" tab (plan R9 6.2): periods of both people on one time line.
class PairPeriodsTab extends StatefulWidget {
  final PairTimeline? timeline;
  final PairNames names;
  final ContentRepository content;
  final double now;
  const PairPeriodsTab({super.key, required this.timeline, required this.names, required this.content, required this.now});

  @override
  State<PairPeriodsTab> createState() => _PairPeriodsTabState();
}

/// One row of the time line: a period, a 7th-house ingress or a calmer window.
class _Row {
  final double start;
  final PairPeriod? period;
  final PairHouseIngress? ingress;
  final CalmWindow? calm;
  const _Row(this.start, {this.period, this.ingress, this.calm});
}

class _PairPeriodsTabState extends State<PairPeriodsTab> {
  PeriodFilter _filter = PeriodFilter.strain;
  bool _past = false;

  bool _shows(PairPeriod p) => switch (_filter) {
        PeriodFilter.strain => p.isStraining,
        PeriodFilter.support => !p.isStraining,
        PeriodFilter.all => true,
      };

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final tl = widget.timeline;
    final now = widget.now;
    final controls = Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Wrap(spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
        SegmentedButton<PeriodFilter>(
          segments: [for (final f in PeriodFilter.values) ButtonSegment(value: f, label: Text(l.periodFilter(f.name)))],
          selected: {_filter},
          onSelectionChanged: (s) => setState(() => _filter = s.first),
        ),
        FilterChip(label: Text(l.periodPast), selected: _past, onSelected: (v) => setState(() => _past = v)),
      ]),
    );
    if (tl == null) return Column(children: [controls, Expanded(child: Center(child: Text(l.computing)))]);

    bool visible(double end) => _past || end >= now;
    final current = [for (final p in tl.periods) if (_shows(p) && p.start <= now && p.end >= now) p];
    final rows = <_Row>[
      for (final p in tl.periods)
        if (_shows(p) && visible(p.end) && !current.contains(p)) _Row(p.start, period: p),
      if (_filter != PeriodFilter.strain)
        for (final i in tl.ingresses)
          if (visible(i.jd)) _Row(i.jd, ingress: i),
      if (_filter != PeriodFilter.support)
        for (final c in tl.calm)
          if (visible(c.end)) _Row(c.start, calm: c),
    ]..sort((a, b) => a.start.compareTo(b.start));

    final children = <Widget>[controls];
    if (current.isNotEmpty) {
      children.add(_header(context, l.periodNow));
      children.addAll([for (final p in current) _item(context, p)]);
    }
    int? year;
    for (final r in rows) {
      final y = localOfJd(r.start).year;
      if (y != year) {
        year = y;
        children.add(_header(context, '$y'));
      }
      if (r.period != null) {
        children.add(_item(context, r.period!));
      } else if (r.ingress != null) {
        final i = r.ingress!;
        children.add(ListTile(
          dense: true,
          leading: const Icon(Icons.login, size: 18),
          title: Text(l.periodIngress(l.body(i.body), widget.names.of(i.ofFirst))),
          subtitle: Text(fmtDate(localOfJd(i.jd))),
          onTap: () => showEntry(context, widget.content[transitInHouseKey(i.body, 7)], title: l.periodIngress(l.body(i.body), widget.names.of(i.ofFirst))),
        ));
      } else {
        final c = r.calm!;
        children.add(InkWell(
          onTap: () => showEntry(context, widget.content['pair_guide/calm_window'], title: l.periodCalm(monthYear(c.start), monthYear(c.end))),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(children: [
              const Expanded(child: Divider()),
              Flexible(
                flex: 4,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(l.periodCalm(monthYear(c.start), monthYear(c.end)), style: t.labelMedium, textAlign: TextAlign.center),
                ),
              ),
              const Expanded(child: Divider()),
            ]),
          ),
        ));
      }
    }
    if (current.isEmpty && rows.isEmpty) children.add(Padding(padding: const EdgeInsets.all(16), child: Text(l.periodNone, style: t.bodyMedium)));
    children
      ..add(const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: HelpLink()))
      ..add(const SizedBox(height: 32));
    return ListView(children: children);
  }

  Widget _header(BuildContext context, String text) =>
      Padding(padding: const EdgeInsets.fromLTRB(16, 20, 16, 4), child: Text(text, style: Theme.of(context).textTheme.titleMedium));

  Widget _item(BuildContext context, PairPeriod p) {
    final l = AppLocalizations.of(context);
    final title = widget.names.period(l, p);
    final range = l.periodRange(monthYear(p.start), monthYear(p.end));
    if (!p.isStraining) {
      return ListTile(
        dense: true,
        leading: const Icon(Icons.wb_sunny_outlined, size: 18),
        title: Text(title),
        subtitle: Text(range),
        onTap: () => showEntry(context, widget.content[pairPeriodKey(p)], title: title),
      );
    }
    return PeriodCard(period: p, title: title, content: widget.content);
  }
}

/// A straining period: dates, exact passes, "oba najednou", the text and a link to the transit text.
class PeriodCard extends StatelessWidget {
  final PairPeriod period;
  final String title;
  final ContentRepository content;
  const PeriodCard({super.key, required this.period, required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final p = period;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: t.titleMedium),
          const SizedBox(height: 2),
          Text(l.periodRange(monthYear(p.start), monthYear(p.end)), style: t.labelLarge),
          if (p.series.exacts.isNotEmpty)
            Text(l.periodExacts(p.series.exacts.map((x) => fmtDate(localOfJd(x))).join(', ')), style: t.bodySmall),
          if (p.shared)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: ActionChip(
                label: Text(l.periodShared),
                onPressed: () => showEntry(context, content['pair_guide/shared_period'], title: l.periodShared),
              ),
            ),
          EntryView(content[pairPeriodKey(p)], fallbackTitle: title, showTitle: false),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => showEntry(context, content[pairPeriodTransitKey(p)], title: title),
              child: Text(l.periodTransitText),
            ),
          ),
        ]),
      ),
    );
  }
}
