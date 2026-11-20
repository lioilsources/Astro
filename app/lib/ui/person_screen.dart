import 'dart:isolate';

import 'package:astro_core/astro_core.dart';
import 'package:astro_core/content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../logic/people_events.dart';
import '../state.dart';
import 'chart/chart_screen.dart';
import 'entry_view.dart';
import 'format.dart';
import 'people_screen.dart';

String _date(CatalogEvent e) => '${e.day}. ${e.month}. ${e.year}';

String _num(double v, int digits) => v.toStringAsFixed(digits).replaceAll('.', ',');

double _now() => jdFromDateTimeUtc(DateTime.now().toUtc());

/// Person detail: birth data, source and the dated events (defining ones first).
class PersonScreen extends StatelessWidget {
  final Person person;
  const PersonScreen(this.person, {super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final b = person.profile.birth;
    final m = b.moment;
    final defining = person.definingEvents;
    final other = [for (final e in person.catalogEvents) if (!e.defining) e];
    Widget tile(CatalogEvent e) => ListTile(
          leading: Icon(e.defining ? Icons.star : Icons.circle_outlined, size: e.defining ? 24 : 14),
          title: Text(e.label, style: e.defining ? const TextStyle(fontWeight: FontWeight.w600) : null),
          subtitle: Text('${_date(e)} · ${l.eventType(e.type)}'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EventDayScreen(person, e))),
        );
    return Scaffold(
      appBar: AppBar(title: Text(person.name)),
      body: ListView(children: [
        ListTile(
          title: Text('${m.day}. ${m.month}. ${m.year}${m.hour != null ? ', ${m.hour}:${two(m.minute ?? 0)}' : ''} · ${b.placeName ?? ''}'),
          subtitle: Text('${l.reliability}: ${l.reliabilityBadge(person.reliability)}\n${l.source}: ${person.sourceNote}'),
          isThreeLine: true,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: FilledButton.icon(
            icon: const Icon(Icons.auto_awesome),
            label: Text(l.personOpenChart),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChartScreen(person.profile))),
          ),
        ),
        Padding(padding: const EdgeInsets.fromLTRB(16, 16, 16, 0), child: Text(l.personDefining, style: t.titleMedium)),
        if (defining.isEmpty) Padding(padding: const EdgeInsets.all(16), child: Text(l.personNoDefining)),
        for (final e in defining) tile(e),
        if (other.isNotEmpty) Padding(padding: const EdgeInsets.fromLTRB(16, 16, 16, 0), child: Text(l.personOtherEvents, style: t.titleMedium)),
        for (final e in other) tile(e),
        Padding(padding: const EdgeInsets.all(16), child: Text(l.personEventsHint, style: t.bodySmall)),
      ]),
    );
  }
}

/// "Tranzity v den události": transits of the day vs. the natal chart and how unusual the day was.
class EventDayScreen extends ConsumerStatefulWidget {
  final Person person;
  final CatalogEvent event;
  const EventDayScreen(this.person, this.event, {super.key});

  @override
  ConsumerState<EventDayScreen> createState() => _EventDayScreenState();
}

class _EventDayScreenState extends ConsumerState<EventDayScreen> {
  late final Future<EventDay> _day;

  @override
  void initState() {
    super.initState();
    final chart = ref.read(chartProvider(widget.person.profile));
    final jd = widget.event.noonJd(widget.person.profile.birth);
    final death = widget.person.deathJd;
    final now = _now();
    _day = Isolate.run(() => computeEventDay(chart, jd, death, now));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final e = widget.event;
    final hasHouses = widget.person.profile.birth.moment.timeKnown;
    final content = ref.watch(contentProvider).value;
    return Scaffold(
      appBar: AppBar(title: Text(l.eventDayTitle)),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Text(e.label, style: t.titleLarge),
        Text('${widget.person.name} · ${_date(e)}${e.dateJulian != null ? ' ${l.eventJulian(e.dateJulian!)}' : ''} · ${l.eventType(e.type)}'),
        const SizedBox(height: 8),
        if (e.quote != null) Text('„${e.quote}“', style: t.bodySmall?.copyWith(fontStyle: FontStyle.italic)),
        Text('${l.source}: ${e.source}${e.url != null ? '\n${e.url}' : ''}', style: t.bodySmall),
        const SizedBox(height: 8),
        Text(l.eventNoonNote, style: t.bodySmall),
        if (!hasHouses) Text(l.eventNoHouses, style: t.bodySmall),
        const SizedBox(height: 16),
        FutureBuilder<EventDay>(
          future: _day,
          builder: (context, snap) {
            if (!snap.hasData) return Text(snap.hasError ? '${snap.error}' : l.computing);
            final d = snap.data!;
            final pct = d.rank.percentile;
            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(l.eventCheckTitle, style: t.titleMedium),
                    const SizedBox(height: 4),
                    Text(l.eventTension(d.tension.round(), pct)),
                    Text(l.eventUnusual(unusualness(pct)), style: t.titleSmall),
                    Text(l.eventLifeSpan(d.lifeDays), style: t.bodySmall),
                    const SizedBox(height: 8),
                    Text(l.eventRetroNote, style: t.bodySmall),
                  ]),
                ),
              ),
              const SizedBox(height: 16),
              Text(l.eventActiveTransits, style: t.titleMedium),
              if (d.transits.isEmpty) Text(l.eventNoTransits),
              for (final x in d.transits)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Text('${bodyGlyph[x.event.transiting]}${aspectGlyph[x.event.type]}${pointGlyph(x.event.target)}', style: glyphStyle),
                  title: Text(l.transitTitle(l.body(x.event.transiting), l.aspect(x.event.type), l.point(x.event.target))),
                  subtitle: Text('${l.eventOrb(_num(x.orb, 1))} · ${l.strength} ${x.strength}'),
                  onTap: () {
                    final house = d.positions.where((p) => p.body == x.event.transiting).firstOrNull?.house;
                    final inHouse = house == null ? null : content?[transitInHouseKey(x.event.transiting, house)];
                    showEntry(context, content?[transitKey(x.event)],
                        title: l.transitTitle(l.body(x.event.transiting), l.aspect(x.event.type), l.point(x.event.target)),
                        extra: [if (inHouse != null) ...[const Divider(), Text(inHouse.text)]]);
                  },
                ),
              const SizedBox(height: 16),
              Text(l.eventPositions, style: t.titleMedium),
              for (final p in d.positions)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Text(bodyGlyph[p.body]!, style: glyphStyle),
                  title: Text('${l.body(p.body)}: ${lonLabel(l, p.lon)}${p.retrograde ? ' ${l.retrogradeShort}' : ''}'),
                  subtitle: p.house != null ? Text(l.houseN(p.house!)) : null,
                  onTap: p.house == null || content?[transitInHouseKey(p.body, p.house!)] == null
                      ? null
                      : () => showEntry(context, content![transitInHouseKey(p.body, p.house!)], title: '${l.body(p.body)} · ${l.houseN(p.house!)}'),
                ),
            ]);
          },
        ),
      ]),
    );
  }
}

/// Catalog-wide check: event-day tension percentiles of all defining events vs. random days.
class CatalogCheckScreen extends ConsumerStatefulWidget {
  const CatalogCheckScreen({super.key});

  @override
  ConsumerState<CatalogCheckScreen> createState() => _CatalogCheckScreenState();
}

final catalogCheckProvider = FutureProvider<CatalogCheck>((ref) async {
  final people = await ref.watch(peopleProvider.future);
  final lives = [
    for (final p in people)
      if (p.definingEvents.isNotEmpty)
        LifeInput(ref.read(chartProvider(p.profile)), p.deathJd, [for (final e in p.definingEvents) e.noonJd(p.profile.birth)]),
  ];
  return computeCatalogCheck(lives, _now());
});

class _CatalogCheckScreenState extends ConsumerState<CatalogCheckScreen> {
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final check = ref.watch(catalogCheckProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l.catalogCheckTitle)),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Text(l.catalogCheckIntro),
        const SizedBox(height: 16),
        check.when(
          loading: () => Row(children: [
            const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            const SizedBox(width: 12),
            Expanded(child: Text(l.catalogCheckComputing)),
          ]),
          error: (e, _) => Text('$e'),
          data: (c) {
            final s = c.summary;
            if (s == null) return Text(l.catalogCheckNone);
            final verdict = !s.related ? 'none' : (s.effect > 0 ? 'higher' : 'lower');
            String p(double v) => v < 0.001 ? '< 0,001' : _num(v, 3);
            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Every verdict, "no relation" included, gets the same prominent style.
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(l.catalogCheckVerdict(verdict), style: t.titleMedium),
                ),
              ),
              const SizedBox(height: 8),
              Text(l.catalogCheckMean(_num(s.meanPercentile, 1), _num(s.effect, 1))),
              Text(l.catalogCheckTop(_num(100 * s.top20Share, 1), _num(100 * s.top20Expected, 1))),
              Text(l.catalogCheckP(p(s.p), p(s.pTop20))),
              Text(l.catalogCheckCounts(s.events, c.people, s.resamples)),
              const SizedBox(height: 16),
              Text(l.catalogCheckMethod, style: t.bodySmall),
              const SizedBox(height: 8),
              Text(l.eventRetroNote, style: t.bodySmall),
            ]);
          },
        ),
      ]),
    );
  }
}
