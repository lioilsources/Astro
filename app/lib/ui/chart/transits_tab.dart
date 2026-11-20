import 'package:astro_core/astro_core.dart';
import 'package:astro_core/content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/content_repository.dart';
import '../../data/profile.dart';
import '../../l10n/app_localizations.dart';
import '../../logic/compute.dart';
import '../../state.dart';
import '../entry_view.dart';
import '../format.dart';

/// Transits of a natal chart (plan 3.4): today, hour-by-hour day, month calendar, ongoing.
class TransitsTab extends ConsumerStatefulWidget {
  final Chart chart;
  final Profile profile;
  const TransitsTab(this.chart, this.profile, {super.key});
  @override
  ConsumerState<TransitsTab> createState() => _TransitsTabState();
}

class _MonthData {
  final List<TransitEvent> events;
  final List<HouseIngress> ingresses;
  const _MonthData(this.events, this.ingresses);
}

class _TransitsTabState extends ConsumerState<TransitsTab> {
  DateTime _day = DateTime.now();
  int _view = 0;
  Future<_MonthData>? _month;
  DateTime? _monthKey;
  Chart? _chartKey;

  Future<_MonthData> _load() {
    final mk = DateTime(_day.year, _day.month);
    if (_month == null || _monthKey != mk || _chartKey != widget.chart) {
      _monthKey = mk;
      _chartKey = widget.chart;
      final from = jdFromDateTimeUtc(DateTime(mk.year, mk.month, 1).toUtc()) - 1;
      final to = jdFromDateTimeUtc(DateTime(mk.year, mk.month + 1, 1).toUtc()) + 1;
      _month = Future.wait([Compute.events(widget.chart, from, to), Compute.ingresses(widget.chart, from, to)])
          .then((r) => _MonthData(r[0] as List<TransitEvent>, r[1] as List<HouseIngress>));
    }
    return _month!;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final content = ref.watch(contentProvider).value ?? const ContentRepository({}, []);
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
        child: Row(children: [
          IconButton(onPressed: () => setState(() => _day = _day.subtract(const Duration(days: 1))), icon: const Icon(Icons.chevron_left)),
          Expanded(
            child: TextButton(
              onPressed: () async {
                final d = await showDatePicker(context: context, initialDate: _day, firstDate: DateTime(1600), lastDate: DateTime(2199));
                if (d != null) setState(() => _day = DateTime(d.year, d.month, d.day, _day.hour, _day.minute));
              },
              child: Text(fmtDate(_day)),
            ),
          ),
          IconButton(onPressed: () => setState(() => _day = _day.add(const Duration(days: 1))), icon: const Icon(Icons.chevron_right)),
        ]),
      ),
      SegmentedButton<int>(
        showSelectedIcon: false,
        segments: [
          ButtonSegment(value: 0, label: Text(l.transitsToday)),
          ButtonSegment(value: 1, label: Text(l.transitsTimeline)),
          ButtonSegment(value: 2, label: Text(l.transitsCalendar)),
          ButtonSegment(value: 3, label: Text(l.transitsOngoing)),
        ],
        selected: {_view},
        onSelectionChanged: (s) => setState(() => _view = s.first),
      ),
      Expanded(
        child: FutureBuilder<_MonthData>(
          future: _load(),
          builder: (context, snap) {
            if (!snap.hasData) {
              return Center(child: snap.hasError ? Text('${snap.error}') : Text(l.computing));
            }
            final engine = TransitEngine(widget.chart);
            final v = _Views(engine, snap.data!, _day, content, widget.chart);
            return switch (_view) { 0 => v.today(context), 1 => v.timeline(context), 2 => v.calendar(context), _ => v.ongoing(context) };
          },
        ),
      ),
    ]);
  }
}

class _Views {
  final TransitEngine engine;
  final _MonthData data;
  final DateTime day;
  final ContentRepository content;
  final Chart chart;
  _Views(this.engine, this.data, this.day, this.content, this.chart);

  double get _dayStart => jdFromDateTimeUtc(DateTime(day.year, day.month, day.day).toUtc());
  double get _dayEnd => _dayStart + 1;

  /// "Now" for today, local noon for other days.
  double get _moment {
    final now = DateTime.now();
    final isToday = now.year == day.year && now.month == day.month && now.day == day.day;
    return isToday ? jdFromDateTimeUtc(now.toUtc()) : _dayStart + 0.5;
  }

  String _title(AppLocalizations l, TransitEvent e) => l.transitTitle(l.body(e.transiting), l.aspect(e.type), l.point(e.target));

  String _phase(AppLocalizations l, TransitPhase p) => switch (p) {
        TransitPhase.approaching => l.phaseApproaching,
        TransitPhase.exact => l.phaseExact,
        TransitPhase.separating => l.phaseSeparating,
      };

  String _passLabel(AppLocalizations l, TransitEvent e, double jd) {
    final ex = e.nearestExact(jd);
    if (ex == null) return '';
    final n = e.passNumbers[e.exacts.indexOf(ex)];
    if (e.passTotal != null && e.passTotal! > 1) return ' · ${l.passOf(n, e.passTotal!)}';
    if (e.passTotal == null && n > 1) return ' · ${l.pass(n)}';
    return '';
  }

  void _open(BuildContext context, TransitEvent e, double jd) {
    final l = AppLocalizations.of(context);
    final phase = engine.phaseAt(e, jd);
    final natalHouse = e.target.body != null ? chart.houseOf(e.target.body!) : (e.target.angle == Angle.asc ? 1 : 10);
    final concurrent = data.events.where((o) => o != e && o.target == e.target && o.covers(jd) && o.transiting != Body.moon).isNotEmpty;
    final modKey = e.station != null && (e.station! - jd).abs() < 10
        ? 'transit_modifier/station'
        : 'transit_modifier/${phase.name}';
    final ex = e.nearestExact(jd);
    showEntry(context, content[transitKey(e)], title: _title(l, e), extra: [
      const Divider(),
      Text('${fmtDateTime(localOfJd(e.start))} – ${fmtDateTime(localOfJd(e.end))}'
          '${ex != null ? '\n${l.exactAt(fmtDateTime(localOfJd(ex)))}' : ''}'
          '\n${_phase(l, phase)}${_passLabel(l, e, jd)} · ${l.strength} ${engine.strengthAt(e, jd, concurrent: data.events)}'),
      if (natalHouse != null && content['house_area/$natalHouse'] != null) Text(content['house_area/$natalHouse']!.text),
      if (content[modKey] != null) Text(content[modKey]!.text),
      if (concurrent) Text(l.concurrence),
    ]);
  }

  Widget _eventTile(BuildContext context, TransitEvent e, double jd) {
    final l = AppLocalizations.of(context);
    final s = engine.strengthAt(e, jd, concurrent: data.events);
    final phase = engine.phaseAt(e, jd);
    return ListTile(
      dense: true,
      leading: SizedBox(
        width: 56,
        child: Row(children: [glyphText(bodyGlyph[e.transiting]!), glyphText(aspectGlyph[e.type]!, size: 14), Text(pointGlyph(e.target), style: glyphStyle)]),
      ),
      title: Text(_title(l, e)),
      subtitle: Text('${_phase(l, phase)}${_passLabel(l, e, jd)}${e.station != null ? ' · ${l.station}' : ''} · ${fmtDate(localOfJd(e.start))} – ${fmtDate(localOfJd(e.end))}'),
      trailing: TransitEngine.isAcute(s)
          ? Chip(label: Text(l.acute), visualDensity: VisualDensity.compact)
          : Text('$s', style: Theme.of(context).textTheme.labelLarge),
      onTap: () => _open(context, e, jd),
    );
  }

  Widget today(BuildContext context) {
    final l = AppLocalizations.of(context);
    final jd = _moment;
    final active = data.events.where((e) => e.covers(jd)).toList()
      ..sort((a, b) => engine.strengthAt(b, jd, concurrent: data.events).compareTo(engine.strengthAt(a, jd, concurrent: data.events)));
    if (active.isEmpty) return Center(child: Text(l.noTransits));
    final acute = active.where((e) => TransitEngine.isAcute(engine.strengthAt(e, jd, concurrent: data.events))).toList();
    final top = active.first;
    final layers = {
      TransitLayer.background: l.layerBackground,
      TransitLayer.weeks: l.layerWeeks,
      TransitLayer.days: l.layerDays,
      TransitLayer.hours: l.layerHours,
    };
    return ListView(padding: const EdgeInsets.only(bottom: 32), children: [
      Padding(
        padding: const EdgeInsets.all(16),
        child: Text(l.todaySentence('${_title(l, top)} (${_phase(l, engine.phaseAt(top, jd))})'), style: Theme.of(context).textTheme.titleMedium),
      ),
      for (final e in acute) _eventTile(context, e, jd),
      for (final layer in layers.entries) ...[
        if (active.any((e) => e.layer == layer.key && !acute.contains(e)))
          Padding(padding: const EdgeInsets.fromLTRB(16, 16, 16, 0), child: Text(layer.value, style: Theme.of(context).textTheme.titleSmall)),
        for (final e in active.where((e) => e.layer == layer.key && !acute.contains(e))) _eventTile(context, e, jd),
      ],
    ]);
  }

  Widget timeline(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final s0 = _dayStart, s1 = _dayEnd;
    final rows = <(double, Widget)>[];
    for (final e in data.events) {
      if (e.transiting == Body.moon && e.end >= s0 && e.start <= s1) {
        rows.add((_max(e.start, s0), _segment(context, e, s0, s1)));
      } else {
        for (final ex in e.exacts) {
          if (ex >= s0 && ex < s1) {
            rows.add((
              ex,
              ListTile(
                dense: true,
                leading: Text(fmtTime(localOfJd(ex)), style: t.labelLarge),
                title: Text(_title(l, e)),
                subtitle: Text(l.exactAt(fmtTime(localOfJd(ex)))),
                onTap: () => _open(context, e, ex),
              )
            ));
          }
        }
      }
    }
    for (final i in data.ingresses.where((i) => i.jd >= s0 && i.jd < s1)) {
      rows.add((
        i.jd,
        ListTile(dense: true, leading: Text(fmtTime(localOfJd(i.jd)), style: t.labelLarge), title: Text(l.ingress(l.body(i.body), i.house)))
      ));
    }
    final now = jdFromDateTimeUtc(DateTime.now().toUtc());
    if (now >= s0 && now < s1) {
      rows.add((now, Row(children: [const SizedBox(width: 16), Text(l.now, style: t.labelLarge?.copyWith(color: Theme.of(context).colorScheme.error)), const Expanded(child: Divider(indent: 8, endIndent: 16))])));
    }
    rows.sort((a, b) => a.$1.compareTo(b.$1));
    if (rows.isEmpty) return Center(child: Text(l.noTransits));
    return ListView(padding: const EdgeInsets.only(bottom: 32), children: [for (final r in rows) r.$2]);
  }

  Widget _segment(BuildContext context, TransitEvent e, double s0, double s1) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final a = ((e.start - s0) / (s1 - s0)).clamp(0.0, 1.0), b = ((e.end - s0) / (s1 - s0)).clamp(0.0, 1.0);
    final ex = e.exacts.isEmpty ? null : ((e.exacts.first - s0) / (s1 - s0));
    return ListTile(
      dense: true,
      leading: Text(fmtTime(localOfJd(e.start < s0 ? s0 : e.start)), style: Theme.of(context).textTheme.labelLarge),
      title: Text(_title(l, e)),
      subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('${fmtTime(localOfJd(e.start))} – ${fmtTime(localOfJd(e.end))}${e.exacts.isNotEmpty ? ' · ${l.exactAt(fmtTime(localOfJd(e.exacts.first)))}' : ''}'),
        const SizedBox(height: 4),
        LayoutBuilder(
          builder: (c, box) => SizedBox(
            height: 8,
            child: Stack(children: [
              Container(color: scheme.surfaceContainerHighest),
              Positioned(left: box.maxWidth * a, width: box.maxWidth * (b - a), top: 0, bottom: 0, child: Container(color: scheme.primary.withValues(alpha: 0.5))),
              if (ex != null && ex >= 0 && ex <= 1) Positioned(left: box.maxWidth * ex - 1, width: 2, top: 0, bottom: 0, child: Container(color: scheme.primary)),
            ]),
          ),
        ),
      ]),
      onTap: () => _open(context, e, e.exacts.isNotEmpty ? e.exacts.first : (e.start + e.end) / 2),
    );
  }

  Widget calendar(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final first = DateTime(day.year, day.month, 1);
    final days = DateTime(day.year, day.month + 1, 0).day;
    final out = <Widget>[];
    for (var d = 0; d < days; d++) {
      final date = first.add(Duration(days: d));
      final s0 = jdFromDateTimeUtc(DateTime(date.year, date.month, date.day).toUtc()), s1 = s0 + 1;
      bool inDay(double x) => x >= s0 && x < s1;
      final items = <String>[];
      for (final e in data.events.where((e) => e.transiting != Body.moon)) {
        if (inDay(e.start)) items.add('▸ ${_title(l, e)}');
        for (final ex in e.exacts) {
          if (inDay(ex)) items.add('● ${_title(l, e)} ${fmtTime(localOfJd(ex))}');
        }
        if (inDay(e.end)) items.add('◂ ${_title(l, e)}');
      }
      if (items.isEmpty) continue;
      out.add(Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(fmtDate(date), style: t.titleSmall),
          for (final i in items) Text(i, style: t.bodySmall),
        ]),
      ));
    }
    if (out.isEmpty) return Center(child: Text(l.noTransits));
    return ListView(padding: const EdgeInsets.only(bottom: 32), children: out);
  }

  Widget ongoing(BuildContext context) {
    final l = AppLocalizations.of(context);
    final jd = _moment;
    final list = data.events
        .where((e) => e.covers(jd) && (e.layer == TransitLayer.background || e.layer == TransitLayer.weeks))
        .toList()
      ..sort((a, b) => a.start.compareTo(b.start));
    if (list.isEmpty) return Center(child: Text(l.noTransits));
    return ListView(children: [for (final e in list) _eventTile(context, e, jd)]);
  }
}

double _max(double a, double b) => a > b ? a : b;
