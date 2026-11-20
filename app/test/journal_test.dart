import 'dart:convert';
import 'dart:io';

import 'package:astro/data/journal_store.dart';
import 'package:astro/journal_state.dart';
import 'package:astro/ui/chart/chart_screen.dart';
import 'package:astro/ui/journal/journal_format.dart';
import 'package:astro/ui/journal/journal_screen.dart';
import 'package:astro_core/astro_core.dart';
import 'package:astro_core/journal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'widget_test.dart' show profile, wrap;

class MemoryVault implements KeyVault {
  final values = <String, String>{};
  int writes = 0;
  @override
  Future<String?> read(String name) async => values[name];
  @override
  Future<void> write(String name, String value) async {
    writes++;
    values[name] = value;
  }
}

class MemoryJournalStore extends JournalStore {
  final Map<String, Journal> data;
  MemoryJournalStore([Map<String, Journal>? data]) : data = data ?? {};
  @override
  Future<Journal> load(String profileId) async => data[profileId] ?? Journal();
  @override
  Future<void> save(String profileId, Journal j) async => data[profileId] = j;
  @override
  Future<void> delete(String profileId) async => data.remove(profileId);
}

DayRating r(String id, String day, int rating) => DayRating(id: id, day: day, createdAt: DateTime.utc(2026, 11, 20), rating: rating, jd: 2461000, tension: 50);

void main() {
  group('encrypted journal store', () {
    late Directory dir;
    setUp(() => dir = Directory.systemTemp.createTempSync('journal'));
    tearDown(() => dir.deleteSync(recursive: true));

    test('round trip per profile, encrypted, one key', () async {
      final vault = MemoryVault();
      final store = JournalStore(vault: vault, dir: () async => dir);
      final j = Journal(ratings: [r('a', '2026-11-20', -1)]).startBlind(DateTime(2026, 11, 20));
      await Future.wait([store.save('p1', j), store.save('p2', Journal())]);
      expect(vault.writes, 1);
      expect((await store.load('p1')).toJson(), j.toJson());
      expect((await store.load('p2')).ratings, isEmpty);
      expect((await store.load('unknown')).ratings, isEmpty);
      final raw = File('${dir.path}/${JournalStore.pathOf('p1')}').readAsBytesSync();
      expect(latin1.decode(raw, allowInvalid: true).contains('rating'), isFalse);
      await store.delete('p1');
      expect((await store.load('p1')).ratings, isEmpty);
    });

    test('a file from a newer app is refused, not overwritten', () async {
      final store = JournalStore(vault: MemoryVault(), dir: () async => dir);
      await store.files.write(JournalStore.pathOf('p'), {'schema': journalSchema + 1, 'ratings': []});
      expect(() => store.load('p'), throwsA(isA<JournalSchemaError>()));
    });

    test('a file without schema (first format) still loads', () async {
      final store = JournalStore(vault: MemoryVault(), dir: () async => dir);
      await store.files.write(JournalStore.pathOf('p'), {
        'ratings': [
          {'id': 'a', 'day': '2026-11-19', 'created': '2026-11-19T20:00:00.000Z', 'rating': 2, 'jd': 2461000.0, 'tension': 10.0}
        ]
      });
      final j = await store.load('p');
      expect(j.ratings.single.formulaVersion, 0);
    });
  });

  test('formatting', () {
    expect(fmtNum(-0.3214), '−0,32');
    expect(fmtShare(0), '< 0,01 %');
    expect(fmtShare(0.0042), '0,42 %');
    expect(fmtShare(0.38), '38 %');
  });

  group('screens', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({'onboardingDone': true});
      JournalNotifier.clock = () => DateTime(2026, 11, 20, 21);
    });
    tearDown(() => JournalNotifier.clock = DateTime.now);

    Widget app(Widget child, JournalStore store) => ProviderScope(
          overrides: [journalStoreProvider.overrideWithValue(store)],
          child: wrap(child),
        );

    testWidgets('journal says "too little data" and rates today', (t) async {
      t.view.physicalSize = const Size(1170, 2532);
      t.view.devicePixelRatio = 3;
      addTearDown(t.view.reset);
      final store = MemoryJournalStore();
      final chart = Chart.compute(profile.birth);
      await t.pumpWidget(app(JournalScreen(profile, chart), store));
      await t.pumpAndSettle();
      await t.runAsync(() => Future<void>.delayed(const Duration(seconds: 2)));
      await t.pumpAndSettle();
      expect(find.text('Zatím málo dat: 0 z 60 ohodnocených dní.'), findsOneWidget);
      await t.tap(find.text('Ohodnotit dnešek'));
      await t.pumpAndSettle();
      await t.tap(find.text('−2'));
      await t.tap(find.text('Uložit'));
      await t.pumpAndSettle();
      final saved = store.data[profile.id]!.ratings.single;
      expect(saved.day, '2026-11-20');
      expect(saved.rating, -2);
      expect(saved.sawPrediction, isTrue);
      expect(saved.formulaVersion, tensionFormulaVersion);
      expect(find.text('Změnit hodnocení'), findsOneWidget);
    });

    testWidgets('blind test locks the transits tab until today is rated', (t) async {
      t.view.physicalSize = const Size(1170, 2532);
      t.view.devicePixelRatio = 3;
      addTearDown(t.view.reset);
      final store = MemoryJournalStore({profile.id: Journal().startBlind(DateTime(2026, 11, 1))});
      await t.pumpWidget(app(const ChartScreen(profile), store));
      await t.pumpAndSettle();
      await t.tap(find.text('Tranzity'));
      await t.pumpAndSettle();
      expect(find.text('Slepý test: tranzity se odemknou, až ohodnotíš dnešek.'), findsOneWidget);
      await t.tap(find.text('Ohodnotit dnešek'));
      await t.pumpAndSettle();
      await t.tap(find.text('Uložit'));
      await t.pumpAndSettle();
      expect(find.text('Slepý test: tranzity se odemknou, až ohodnotíš dnešek.'), findsNothing);
      expect(store.data[profile.id]!.ratings.single.sawPrediction, isFalse);
    });
  });
}
