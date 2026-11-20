import 'package:astro_core/astro_core.dart';
import 'package:astro_core/content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/content_repository.dart';
import '../../data/profile.dart';
import '../../data/settings.dart';
import '../../l10n/app_localizations.dart';
import '../../logic/compute.dart';
import '../../state.dart';
import '../entry_view.dart';
import '../format.dart';
import '../wheel.dart';
import 'transits_tab.dart';

/// Which time technique the profile shows (plan 10.5).
enum TimeMode { transits, progressions, solar }

class TimeModeNotifier extends Notifier<TimeMode> {
  TimeModeNotifier(this.profileId);
  final String profileId;
  @override
  TimeMode build() => TimeMode.transits;
  void set(TimeMode m) => state = m;
}

/// Remembered per profile for the session.
final timeModeProvider = NotifierProvider.family<TimeModeNotifier, TimeMode, String>(TimeModeNotifier.new);

/// Transits / progressions / solar return switch of a profile.
class TimeTab extends ConsumerWidget {
  final Chart chart;
  final Profile profile;
  const TimeTab(this.chart, this.profile, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final mode = ref.watch(timeModeProvider(profile.id));
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
        child: SegmentedButton<TimeMode>(
          showSelectedIcon: false,
          segments: [
            ButtonSegment(value: TimeMode.transits, label: Text(l.timeModeTransits)),
            ButtonSegment(value: TimeMode.progressions, label: Text(l.timeModeProgressions)),
            ButtonSegment(value: TimeMode.solar, label: Text(l.timeModeSolar)),
          ],
          selected: {mode},
          onSelectionChanged: (s) => ref.read(timeModeProvider(profile.id).notifier).set(s.first),
        ),
      ),
      Expanded(
        child: switch (mode) {
          TimeMode.transits => TransitsTab(chart, profile),
          TimeMode.progressions => ProgressionsView(chart, profile),
          TimeMode.solar => SolarReturnView(chart, profile),
        },
      ),
    ]);
  }
}

ListTile _entryTile(BuildContext context, ContentRepository content, String key, String title, {String? subtitle, List<Widget> extra = const []}) =>
    ListTile(
      dense: true,
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle),
      trailing: content[key] == null ? null : const Icon(Icons.chevron_right),
      onTap: () => showEntry(context, content[key], title: title, extra: extra),
    );

Widget _header(BuildContext context, String text) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(text, style: Theme.of(context).textTheme.titleSmall),
    );

/// Secondary progressions for a date and the life timeline.
class ProgressionsView extends ConsumerStatefulWidget {
  final Chart chart;
  final Profile profile;
  const ProgressionsView(this.chart, this.profile, {super.key});
  @override
  ConsumerState<ProgressionsView> createState() => _ProgressionsViewState();
}

class _ProgressionsViewState extends ConsumerState<ProgressionsView> {
  DateTime _day = DateTime.now();
  Future<(Progression, LifeTimeline)>? _future;
  (Chart, DateTime)? _key;
  Future<LifeTimeline>? _timeline;
  Chart? _timelineKey;
  bool _houses = false;

  Future<(Progression, LifeTimeline)> _load() {
    final k = (widget.chart, _day);
    if (_future == null || _key != k) {
      _key = k;
      if (_timeline == null || _timelineKey != widget.chart) {
        _timelineKey = widget.chart;
        _timeline = Progressions.timeline(widget.chart);
      }
      final jd = jdFromDateTimeUtc(DateTime(_day.year, _day.month, _day.day, 12).toUtc());
      _future = Future.wait([Progressions.at(widget.chart, jd), _timeline!]).then((r) => (r[0] as Progression, r[1] as LifeTimeline));
    }
    return _future!;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final content = ref.watch(contentProvider).value ?? const ContentRepository({}, []);
    return FutureBuilder<(Progression, LifeTimeline)>(
      future: _load(),
      builder: (context, snap) {
        if (!snap.hasData) return Center(child: snap.hasError ? Text('${snap.error}') : Text(l.computing));
        final (p, tl) = snap.data!;
        return ListView(children: [
          Row(children: [
            IconButton(onPressed: () => setState(() => _day = DateTime(_day.year - 1, _day.month, _day.day)), icon: const Icon(Icons.chevron_left)),
            Expanded(
              child: TextButton(
                onPressed: () async {
                  final first = localOfJd(widget.chart.time.jdUt);
                  final d = await showDatePicker(context: context, initialDate: _day, firstDate: first, lastDate: DateTime(first.year + 100));
                  if (d != null) setState(() => _day = d);
                },
                child: Text(fmtDate(_day)),
              ),
            ),
            IconButton(onPressed: () => setState(() => _day = DateTime(_day.year + 1, _day.month, _day.day)), icon: const Icon(Icons.chevron_right)),
          ]),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(l.progressionsAge(p.ageYears.toStringAsFixed(1), fmtDate(localOfJd(p.jdUt))), style: Theme.of(context).textTheme.bodySmall),
          ),
          if (!widget.chart.timeKnown)
            Padding(padding: const EdgeInsets.fromLTRB(16, 4, 16, 0), child: Text(l.progressedNoTime, style: Theme.of(context).textTheme.bodySmall)),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ChartWheel(widget.chart, outer: {for (final b in Body.planets) if (p.positions[b] != null) b: p.positions[b]!.lon}),
          ),
          ..._now(context, l, content, p),
          _header(context, l.lifeTimeline),
          SwitchListTile(dense: true, title: Text(l.timelineMoonHouses), value: _houses, onChanged: (v) => setState(() => _houses = v)),
          ..._timelineRows(context, l, content, tl, p.lifeJd),
        ]);
      },
    );
  }

  List<Widget> _now(BuildContext context, AppLocalizations l, ContentRepository content, Progression p) {
    final h = p.moonHouse;
    final phase = p.lunarPhase;
    return [
      _entryTile(context, content, progressedMoonSignKey(p.moon.sign), '${l.progressedMoon}: ${l.sign(p.moon.sign)}', subtitle: lonLabel(l, p.moon.lon)),
      if (h != null) _entryTile(context, content, progressedMoonHouseKey(h), '${l.progressedMoon}: ${l.houseN(h)}'),
      _entryTile(context, content, progressedSunSignKey(p.sun.sign), '${l.progressedSun}: ${l.sign(p.sun.sign)}', subtitle: lonLabel(l, p.sun.lon)),
      _entryTile(context, content, progressedLunarPhaseKey(phase), '${l.progressedPhase}: ${l.moonPhaseName(phase.id)}'),
      if (p.mc != null)
        ListTile(
          dense: true,
          title: Text(l.progressedAngles(formatDm(p.solarArc))),
          subtitle: Text('${l.bodyName('asc')} ${lonLabel(l, p.asc!)} · ${l.bodyName('mc')} ${lonLabel(l, p.mc!)}'),
        ),
      _header(context, l.progressedAspects),
      if (p.aspects.isEmpty)
        Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text(l.progressedAspectsNone, style: Theme.of(context).textTheme.bodySmall)),
      for (final a in p.aspects)
        () {
          final mod = content[progressedModifierKey(a)];
          return _entryTile(
            context,
            content,
            progressedAspectKey(a),
            l.progressedAspectTitle(l.body(a.progressed), l.aspect(a.type), l.point(a.natal)),
            subtitle: a.applying ? l.progressedApplying(formatDm(a.orb)) : l.progressedSeparating(formatDm(a.orb)),
            // Plan 10.5: the transit text, introduced by the progression sentence.
            extra: [if (mod != null) Text(mod.text, style: Theme.of(context).textTheme.bodySmall)],
          );
        }(),
    ];
  }

  List<Widget> _timelineRows(BuildContext context, AppLocalizations l, ContentRepository content, LifeTimeline tl, double now) {
    final birth = widget.chart.time.jdUt;
    String age(double jd) => l.milestoneAge(((jd - birth) / tropicalYearDays).floor().toString());
    final rows = <(double, Widget)>[];
    for (final m in tl.milestones) {
      if (m.kind == MilestoneKind.moonHouse && !_houses) continue;
      final (key, title) = switch (m.kind) {
        MilestoneKind.moonSign => (progressedMoonSignKey(m.sign!), l.milestoneMoonSign(l.sign(m.sign!))),
        MilestoneKind.sunSign => (progressedSunSignKey(m.sign!), l.milestoneSunSign(l.sign(m.sign!))),
        MilestoneKind.moonHouse => (progressedMoonHouseKey(m.house!), l.milestoneMoonHouse(m.house!)),
        MilestoneKind.lunarPhase => (progressedLunarPhaseKey(m.phase!), l.milestoneLunarPhase(l.moonPhaseName(m.phase!.id))),
        MilestoneKind.solarReturn => ('', ''),
      };
      rows.add((m.jdUt, _entryTile(context, content, key, title, subtitle: '${fmtDate(localOfJd(m.jdUt))} · ${age(m.jdUt)}')));
    }
    for (final sr in tl.solarReturns) {
      rows.add((
        sr.jdUt,
        ListTile(
          dense: true,
          leading: const Icon(Icons.wb_sunny_outlined, size: 18),
          title: Text(l.milestoneSolarReturn(sr.year)),
          subtitle: Text('${fmtDateTime(localOfJd(sr.jdUt))} · ${age(sr.jdUt)}'),
          onTap: () {
            ref.read(solarYearProvider(widget.profile.id).notifier).set(sr.year);
            ref.read(timeModeProvider(widget.profile.id).notifier).set(TimeMode.solar);
          },
        ),
      ));
    }
    rows.sort((a, b) => a.$1.compareTo(b.$1));
    final scheme = Theme.of(context).colorScheme;
    return [
      for (final r in rows)
        r.$1 <= now ? r.$2 : DecoratedBox(decoration: BoxDecoration(border: Border(left: BorderSide(color: scheme.primary, width: 3))), child: r.$2),
    ];
  }
}

class SolarYearNotifier extends Notifier<int?> {
  SolarYearNotifier(this.profileId);
  final String profileId;
  @override
  int? build() => null;
  void set(int? y) => state = y;
}

/// Chosen solar-return year per profile (null = the current solar year).
final solarYearProvider = NotifierProvider.family<SolarYearNotifier, int?, String>(SolarYearNotifier.new);

/// Solar return of a year at the residence, switchable to the birth place (owner decision 17).
class SolarReturnView extends ConsumerStatefulWidget {
  final Chart chart;
  final Profile profile;
  const SolarReturnView(this.chart, this.profile, {super.key});
  @override
  ConsumerState<SolarReturnView> createState() => _SolarReturnViewState();
}

class _SolarReturnViewState extends ConsumerState<SolarReturnView> {
  bool _birthPlace = false;
  Future<({SolarReturn sr, Chart chart})>? _future;
  Object? _key;

  int _currentYear() => SolarReturn.current(widget.chart, jdFromDateTimeUtc(DateTime.now().toUtc())).year;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final content = ref.watch(contentProvider).value ?? const ContentRepository({}, []);
    final settings = ref.watch(settingsProvider).value ?? const AppSettings();
    final year = ref.watch(solarYearProvider(widget.profile.id)) ?? _currentYear();
    final place = _birthPlace ? GeoLocation.ofBirth(widget.chart.birth) : widget.profile.residencePlace;
    final options = settings.chartOptions(widget.profile.houseSystem);
    final key = (widget.chart, year, place, options.houseSystem, options.node, options.orbs);
    if (_future == null || _key != key) {
      _key = key;
      _future = Progressions.solarReturn(widget.chart, year, place, options);
    }
    void setYear(int y) => ref.read(solarYearProvider(widget.profile.id).notifier).set(y);
    return ListView(children: [
      Row(children: [
        IconButton(onPressed: () => setYear(year - 1), icon: const Icon(Icons.chevron_left)),
        Expanded(child: Center(child: Text(l.solarReturnTitle(year), style: t.titleMedium))),
        IconButton(onPressed: () => setYear(year + 1), icon: const Icon(Icons.chevron_right)),
      ]),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: SegmentedButton<bool>(
          showSelectedIcon: false,
          segments: [
            ButtonSegment(value: false, label: Text(l.solarPlaceResidence)),
            ButtonSegment(value: true, label: Text(l.solarPlaceBirth)),
          ],
          selected: {_birthPlace},
          onSelectionChanged: (s) => setState(() => _birthPlace = s.first),
        ),
      ),
      FutureBuilder<({SolarReturn sr, Chart chart})>(
        future: _future,
        builder: (context, snap) {
          if (!snap.hasData) {
            return Padding(padding: const EdgeInsets.all(24), child: Center(child: snap.hasError ? Text('${snap.error}') : Text(l.computing)));
          }
          final (:sr, :chart) = snap.data!;
          final zone = place.zone;
          final when = zone != null ? utToZone(sr.jdUt, zone) : localOfJd(sr.jdUt);
          final asc = chart.asc;
          final h = chart.houseOf(Body.sun);
          final onAngles = planetsOnAngles(chart);
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(
                '${l.solarReturnMoment(lonLabel(l, sr.sunLon), '${fmtDate(when)} ${fmtTime(when)}:${two(when.second)}')}\n'
                '${l.solarPlace(place.name ?? '${place.lat.toStringAsFixed(2)}, ${place.lon.toStringAsFixed(2)}')}',
                style: t.bodySmall,
              ),
            ),
            if (!widget.chart.timeKnown) Padding(padding: const EdgeInsets.fromLTRB(16, 4, 16, 0), child: Text(l.solarNoTime, style: t.bodySmall)),
            Padding(padding: const EdgeInsets.all(16), child: ChartWheel(chart)),
            if (asc != null)
              _entryTile(context, content, solarReturnAscKey(Sign.ofLongitude(asc)), '${l.solarAsc}: ${l.sign(Sign.ofLongitude(asc))}', subtitle: lonLabel(l, asc)),
            if (h != null) _entryTile(context, content, solarReturnSunHouseKey(h), '${l.solarSunHouse}: ${l.houseN(h)}'),
            _header(context, l.solarOnAngles),
            if (onAngles.isEmpty) Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text(l.solarNoAngles, style: t.bodySmall)),
            for (final x in onAngles)
              _entryTile(context, content, planetOnAngleKey(x.body, x.angle), l.planetOnAngle(l.body(x.body), l.returnAngleName(x.angle.name)),
                  subtitle: formatDm(x.orb)),
            _header(context, l.solarPlanets),
            for (final b in Body.planets)
              if (chart.positions[b] != null)
                ListTile(
                  dense: true,
                  leading: Text(bodyGlyph[b]!, style: glyphStyle.copyWith(fontSize: 18)),
                  title: Text('${l.body(b)} ${lonLabel(l, chart.positions[b]!.lon)}'),
                  trailing: chart.houseOf(b) == null ? null : Text(l.houseN(chart.houseOf(b)!)),
                ),
          ]);
        },
      ),
    ]);
  }
}
