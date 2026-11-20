import 'dart:convert';

import 'package:astro_core/astro_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/profile.dart';
import '../l10n/app_localizations.dart';
import 'chart/chart_screen.dart';

/// A sourced catalog record (Prompts/KATALOG-osobnosti.md). Only records with a source ship.
class Person {
  final String id;
  final String name;
  final List<String> categories;
  final String reliability;
  final String sourceNote;
  final Profile profile;
  const Person(this.id, this.name, this.categories, this.reliability, this.sourceNote, this.profile);

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
    final events = [
      for (final e in (j['events'] as List? ?? const []).cast<Map>())
        () {
          final p = (e['date'] as String).split('-').map(int.parse).toList();
          return LifeEvent('${j['id']}-${e['date']}', julianDay(p[0], p[1], p[2], 12), e['label'] as String);
        }()
    ];
    return Person(
      j['id'] as String,
      j['name'] as String,
      (j['categories'] as List).cast<String>(),
      j['reliability'] as String,
      ((j['source'] as Map?)?['note'] as String?) ?? '',
      Profile(id: 'catalog-${j['id']}', name: j['name'] as String, birth: birth, events: events, catalogId: j['id'] as String),
    );
  }
}

final peopleProvider = FutureProvider<List<Person>>((ref) async {
  final raw = await rootBundle.loadString('assets/data/people.json');
  return [for (final p in (jsonDecode(raw) as List).cast<Map>()) Person.fromJson(p.cast<String, Object?>())];
});

class PeopleScreen extends ConsumerWidget {
  const PeopleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final people = ref.watch(peopleProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l.navPeople)),
      body: people.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (list) => list.isEmpty
            ? Center(child: Padding(padding: const EdgeInsets.all(32), child: Text(l.peopleEmpty, textAlign: TextAlign.center)))
            : ListView(children: [
                for (final p in list)
                  ListTile(
                    title: Text(p.name),
                    subtitle: Text('${l.reliability}: ${p.reliability} · ${l.source}: ${p.sourceNote}'),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChartScreen(p.profile))),
                  ),
              ]),
      ),
    );
  }
}
