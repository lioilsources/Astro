import 'dart:io';

import 'package:astro/data/pairs.dart';
import 'package:astro/export/pair_pdf.dart';
import 'package:astro/l10n/app_localizations.dart';
import 'package:astro/logic/filter.dart';
import 'package:astro/pair_state.dart';
import 'package:astro/ui/synastry/pair_names.dart';
import 'package:astro/ui/synastry/pair_periods_tab.dart';
import 'package:astro/ui/synastry/synastry_screen.dart';
import 'package:astro_core/astro_core.dart';
import 'package:astro_core/content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'journal_test.dart' show MemoryVault;
import 'synastry_test.dart' show MemoryPairStore, anna, markedContent, petr, settle, wrap;

void tall(WidgetTester t) {
  t.view.physicalSize = const Size(1170, 60000);
  t.view.devicePixelRatio = 3;
  addTearDown(t.view.reset);
}

const names = PairNames('Anna', 'Petr');

PairPeriod period(bool ofFirst, double start, double end, {Body body = Body.saturn, ChartPoint target = const ChartPoint.body(Body.venus), PairPeriodKind kind = PairPeriodKind.strain, bool shared = false}) =>
    PairPeriod(
      ofFirst,
      kind,
      TransitSeries(body, target, AspectType.square, 1, start, end, [start + 30, end - 30], null, const []),
      null,
      40,
      shared: shared,
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({'onboardingDone': true}));

  group('guide tab', () {
    testWidgets('chapters, a full text once, "Co s tím"', (t) async {
      tall(t);
      await t.pumpWidget(wrap(SynastryResultScreen(anna, petr, Relationship.partner), content: markedContent()));
      await settle(t);
      for (final c in ['Přehled', 'V čem si vyhovíte', 'Na co si dát pozor', 'Jak spolu mluvit', 'Jak se respektovat', 'Co kdo potřebuje', 'Zátěžová období']) {
        expect(find.text(c), findsOneWidget, reason: c);
      }
      expect(find.text('souzní 5 · tře se 3'), findsOneWidget); // love: from the CLI run of the same pair
      // Sun trine Venus is a strength; it is linked from respect and needs, its text appears once.
      expect(find.text('Mezi vámi synastry/sun/venus/harmonious.'), findsOneWidget);
      expect(find.text('Co s tím'), findsWidgets);
      expect(find.text('Rada pair_need/moon/taurus.'), findsOneWidget);
      // Both have Mars in Virgo: one need for both, titled with both names.
      expect(find.text('Anna a Petr · Mars v Panně'), findsOneWidget);
      expect(find.text('Petr · Měsíc ve Vahách'), findsOneWidget);
      expect(find.textContaining('Zobrazit další'), findsWidgets);
      // Linked aspect opens the text in a sheet.
      await t.tap(find.text('Slunce (Anna) trigon Venuše (Petr)').last);
      await t.pumpAndSettle();
      expect(find.byType(BottomSheet), findsOneWidget);
    });

    testWidgets('gentle mode hides shadow and hard passages with a "Skryto" line', (t) async {
      tall(t);
      await t.pumpWidget(wrap(SynastryResultScreen(anna, petr, Relationship.friends),
          content: markedContent(), filter: ContentFilter(hiddenTopics: hardTopics.toSet(), hideShadow: true)));
      await settle(t);
      expect(find.textContaining('Stín pair_need'), findsNothing);
      expect(find.textContaining('Tradice synastry'), findsNothing);
      expect(find.textContaining('Skryto: 2'), findsWidgets);
      // Advice is not filtered.
      expect(find.text('Rada pair_need/moon/taurus.'), findsOneWidget);
    });
  });

  group('periods tab', () {
    final now = julianDay(2027, 1, 1, 0);
    final tl = PairTimeline(now - 700, now + 3650, [
      period(true, now - 100, now + 100, shared: true),
      period(false, now + 400, now + 700, body: Body.pluto, target: const ChartPoint.body(Body.sun)),
      period(true, now + 800, now + 900, body: Body.jupiter, kind: PairPeriodKind.support),
      period(true, now - 600, now - 400, body: Body.uranus, target: const ChartPoint.body(Body.mars)),
    ], [
      PairHouseIngress(false, Body.saturn, now + 1000),
    ], [
      CalmWindow(now + 1200, now + 1500),
    ]);

    Widget host() => wrap(Scaffold(body: PairPeriodsTab(timeline: tl, names: names, content: markedContent(), now: now)));

    testWidgets('running period on top, cards with dates and "oba najednou", toggles', (t) async {
      tall(t);
      await t.pumpWidget(host());
      await t.pumpAndSettle();
      expect(find.text('Právě probíhá'), findsOneWidget);
      expect(find.text('Anna: Saturn kvadrát Venuše'), findsOneWidget);
      expect(find.text('oba najednou'), findsOneWidget);
      expect(find.text('Petr: Pluto kvadrát Slunce'), findsOneWidget);
      expect(find.textContaining('přesně: '), findsNWidgets(2));
      expect(find.text('Výklad tranzitu'), findsNWidgets(2));
      expect(find.textContaining('Klidnější okno'), findsOneWidget);
      // Support and the past are hidden by default.
      expect(find.text('Anna: Jupiter kvadrát Venuše'), findsNothing);
      expect(find.text('Anna: Uran kvadrát Mars'), findsNothing);
      await t.tap(find.text('Minulost'));
      await t.pumpAndSettle();
      expect(find.text('Anna: Uran kvadrát Mars'), findsOneWidget);
      await t.tap(find.text('Příznivá'));
      await t.pumpAndSettle();
      expect(find.text('Anna: Jupiter kvadrát Venuše'), findsOneWidget);
      expect(find.text('Saturn vstupuje do 7. domu: Petr'), findsOneWidget);
      expect(find.text('Anna: Saturn kvadrát Venuše'), findsNothing);
      expect(find.textContaining('Klidnější okno'), findsNothing);
    });
  });

  group('saved pairs', () {
    late Directory dir;
    setUp(() => dir = Directory.systemTemp.createTempSync('pairs'));
    tearDown(() => dir.deleteSync(recursive: true));

    test('survive a reload of the encrypted store', () async {
      final vault = MemoryVault();
      await PairStore(vault: vault, dir: () async => dir)
          .save(const [Pair(id: '1', firstId: 'a', secondId: 'b', relationship: Relationship.siblings)]);
      expect(String.fromCharCodes(File('${dir.path}/pairs.bin').readAsBytesSync()).contains('siblings'), isFalse, reason: 'encrypted');
      final back = await PairStore(vault: vault, dir: () async => dir).load();
      expect(back.single.relationship, Relationship.siblings);
      expect((back.single.firstId, back.single.secondId), ('a', 'b'));
    });

    test('adding the same two people updates the pair; deleting a profile removes its pairs', () async {
      final store = MemoryPairStore();
      final c = ProviderContainer(overrides: [pairStoreProvider.overrideWithValue(store)]);
      addTearDown(c.dispose);
      final n = c.read(pairsProvider.notifier);
      await c.read(pairsProvider.future);
      await n.add('a', 'b', Relationship.partner);
      await n.add('b', 'a', Relationship.friends);
      await n.add('a', 'c', Relationship.colleagues);
      expect(store.data, hasLength(2));
      expect(store.data.first.relationship, Relationship.friends);
      await n.removeProfile('a');
      expect(store.data, isEmpty);
    });
  });

  test('PDF: every chapter, each text once, no links, coming strain only', () {
    final guide = PairGuide.of(Synastry.compute(Chart.compute(anna.birth), Chart.compute(petr.birth)));
    final now = julianDay(2027, 1, 1, 0);
    final tl = PairTimeline(now, now + 3650, [
      period(true, now - 400, now - 300),
      period(true, now + 10, now + 300),
      period(true, now + 10, now + 300, body: Body.jupiter, kind: PairPeriodKind.support),
    ], const [], const []);
    final items = pairPdfEntries(guide, tl, markedContent(), now: now);
    expect([for (final i in items) if (i.chapter != null) i.chapter],
        ['strengths', 'cautions', 'talk', 'respect', 'needs', 'periods']);
    final keys = [for (final i in items) if (i.block != null) '${i.entry!.key}|${i.block!.need?.ofFirst}'];
    expect(keys.toSet(), hasLength(keys.length));
    expect(items.any((i) => i.block?.linkOnly ?? false), isFalse);
    expect(items.where((i) => i.period != null), hasLength(1));
  });

  testWidgets('PDF builds with the bundled fonts', (t) async {
    final guide = PairGuide.of(Synastry.compute(Chart.compute(anna.birth), Chart.compute(petr.birth)));
    final l = await AppLocalizations.delegate.load(const Locale('cs'));
    final bytes = await t.runAsync(() => buildPairPdf(l, names, guide, const PairTimeline(0, 1, [], [], []), markedContent(), ContentFilter.none,
        relationship: Relationship.parentChild, now: 0));
    expect(bytes!.length, greaterThan(1000));
  });
}
