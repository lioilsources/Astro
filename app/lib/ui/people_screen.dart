import 'dart:convert';

import 'package:astro_core/astro_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/profile.dart';
import '../l10n/app_localizations.dart';
import '../logic/people_events.dart';
import 'person_screen.dart';

/// A sourced catalog record (Prompts/KATALOG-osobnosti.md). Only records with a source ship.
class Person {
  final String id;
  final String name;
  final List<String> categories;
  final String reliability;
  final String sourceNote;
  final Profile profile;

  /// Dated events, chronological; defining ones carry what the person is known for.
  final List<CatalogEvent> catalogEvents;
  final String? sourceUrl;
  const Person(this.id, this.name, this.categories, this.reliability, this.sourceNote, this.profile,
      {this.catalogEvents = const [], this.sourceUrl});

  List<CatalogEvent> get definingEvents => [for (final e in catalogEvents) if (e.defining) e];

  /// Julian Day of death (local noon), null for the living.
  double? get deathJd => catalogEvents.where((e) => e.type == 'death').firstOrNull?.noonJd(profile.birth);

  static Person fromJson(Map<String, Object?> j) {
    final b = (j['birth'] as Map).cast<String, Object?>();
    final d = (b['date'] as String).split('-').map(int.parse).toList();
    final time = (b['time'] as String?)?.split(':').map(int.parse).toList();
    final basis = switch (b['time_basis']) { 'lmt' => TimeBasis.lmt, 'ut' => TimeBasis.ut, _ => TimeBasis.zone };
    final birth = BirthData(
      moment: LocalMoment(
        year: d[0],
        month: d[1],
        day: d[2],
        hour: time?[0],
        minute: time?[1],
        calendar: b['calendar'] == 'julian' ? CalendarKind.julian : CalendarKind.gregorian,
        basis: basis,
        zone: b['zone'] as String?,
      ),
      lat: (b['lat'] as num).toDouble(),
      lon: (b['lon'] as num).toDouble(),
      placeName: b['place'] as String?,
    );
    final catalogEvents = [
      for (final e in (j['events'] as List? ?? const []).cast<Map>()) CatalogEvent.fromJson(e.cast<String, Object?>())
    ]..sort((a, b) => a.date.compareTo(b.date));
    final events = [for (final e in catalogEvents) LifeEvent('${j['id']}-${e.date}', e.noonJd(birth), e.label)];
    final reliability = j['reliability'] as String;
    final sourceNote = ((j['source'] as Map?)?['note'] as String?) ?? '';
    return Person(
      j['id'] as String,
      j['name'] as String,
      (j['categories'] as List).cast<String>(),
      reliability,
      sourceNote,
      Profile(
        id: 'catalog-${j['id']}',
        name: j['name'] as String,
        birth: birth,
        events: events,
        catalogId: j['id'] as String,
        catalogReliability: reliability,
        catalogSource: sourceNote,
      ),
      catalogEvents: catalogEvents,
      sourceUrl: (j['source'] as Map?)?['url'] as String?,
    );
  }

  /// AA and A count as confirmed (plan 4.3).
  bool get confirmed => reliability == 'AA' || reliability == 'A';
}

final peopleProvider = FutureProvider<List<Person>>((ref) async {
  final raw = await rootBundle.loadString('assets/data/people.json');
  return [for (final p in (jsonDecode(raw) as List).cast<Map>()) Person.fromJson(p.cast<String, Object?>())];
});

const _categoryOrder = ['history', 'politics', 'military', 'science', 'art', 'music', 'film', 'celebrity', 'football', 'hockey', 'sport', 'business', 'religion', 'literature'];

class PeopleScreen extends ConsumerStatefulWidget {
  const PeopleScreen({super.key});

  @override
  ConsumerState<PeopleScreen> createState() => _PeopleScreenState();
}

class _PeopleScreenState extends ConsumerState<PeopleScreen> {
  String? _category;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final people = ref.watch(peopleProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l.navPeople), actions: [
        IconButton(
          icon: const Icon(Icons.query_stats),
          tooltip: l.catalogCheckTitle,
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CatalogCheckScreen())),
        ),
      ]),
      body: people.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (list) {
          if (list.isEmpty) {
            return Center(child: Padding(padding: const EdgeInsets.all(32), child: Text(l.peopleEmpty, textAlign: TextAlign.center)));
          }
          final q = _fold(_query);
          final shown = [
            for (final p in list)
              if ((_category == null || p.categories.contains(_category)) && (q.isEmpty || _fold(p.name).contains(q))) p
          ]..sort((a, b) => a.name.compareTo(b.name));
          return Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: TextField(
                decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: l.peopleSearch),
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            SizedBox(
              height: 52,
              child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), children: [
                for (final c in [null, ..._categoryOrder])
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Text(c == null ? l.peopleAll : l.peopleCategory(c)),
                      selected: _category == c,
                      onSelected: (_) => setState(() => _category = c),
                    ),
                  ),
              ]),
            ),
            Expanded(
              child: ListView(children: [
                for (final p in shown) _PersonTile(p),
                Padding(padding: const EdgeInsets.all(16), child: Text(l.peopleSourceNote, style: Theme.of(context).textTheme.bodySmall)),
              ]),
            ),
          ]);
        },
      ),
    );
  }

  static String _fold(String s) {
    const from = 'áäčďéěëíňóöřšťúůüýžľĺôÁÄČĎÉĚËÍŇÓÖŘŠŤÚŮÜÝŽĽĹÔ';
    const to = 'aacdeeeinoorstuuuyzlloAACDEEEINOORSTUUUYZLLO';
    final b = StringBuffer();
    for (final ch in s.split('')) {
      final i = from.indexOf(ch);
      b.write(i < 0 ? ch : to[i]);
    }
    return b.toString().toLowerCase();
  }
}

class _PersonTile extends StatelessWidget {
  final Person p;
  const _PersonTile(this.p);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final b = p.profile.birth;
    final m = b.moment;
    final date = '${m.day}. ${m.month}. ${m.year}${m.hour != null ? ', ${m.hour}:${m.minute.toString().padLeft(2, '0')}' : ''}';
    final icon = switch (p.reliability) {
      'AA' || 'A' => Icon(Icons.verified_outlined, color: scheme.primary),
      'B' => Icon(Icons.info_outline, color: scheme.tertiary),
      'C' => Icon(Icons.warning_amber_outlined, color: scheme.error),
      _ => Icon(Icons.schedule_outlined, color: scheme.outline),
    };
    return ListTile(
      leading: icon,
      title: Text(p.name),
      subtitle: Text('$date · ${b.placeName ?? ''}\n${l.reliability}: ${l.reliabilityBadge(p.reliability)}'),
      isThreeLine: true,
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PersonScreen(p))),
    );
  }
}
