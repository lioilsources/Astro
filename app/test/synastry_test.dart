import 'dart:io';

import 'package:astro/data/content_repository.dart';
import 'package:astro/data/profile.dart';
import 'package:astro/l10n/app_localizations.dart';
import 'package:astro/logic/synastry_reading.dart';
import 'package:astro/state.dart';
import 'package:astro/ui/synastry/synastry_screen.dart';
import 'package:astro_core/astro_core.dart';
import 'package:astro_core/content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'logic_test.dart' show loadContent;

Profile person(String id, String name, int year, int month, int day, int hour, int minute) => Profile(
      id: id,
      name: name,
      birth: BirthData(
        moment: LocalMoment(year: year, month: month, day: day, hour: hour, minute: minute, basis: TimeBasis.ut),
        lat: 50.0833,
        lon: 14.4167,
      ),
    );

final anna = person('a', 'Anna', 1980, 5, 14, 8, 30);
final petr = person('b', 'Petr', 1983, 11, 2, 19, 5);
final twinA = person('t1', 'Ema', 1990, 3, 10, 6, 0);
final twinB = person('t2', 'Ela', 1990, 3, 10, 6, 25);

const partnerMark = 'PARTNERSKÝ-DOVĚTEK';

/// Every synastry key with a text and a marked `partner` layer.
ContentRepository markedContent() => ContentRepository({
      for (final f in ['synastry', 'synastry_point', 'synastry_house'])
        for (final k in allKeysByFamily()[f]!)
          k: ContentEntry(key: k, title: 'Titul $k', text: 'Mezi vámi $k.', shadow: 'Stín $k.', partner: '$partnerMark $k'),
    }, const []);

Widget wrap(Widget child, {ContentRepository? content}) => ProviderScope(
      overrides: [
        contentProvider.overrideWith((ref) async => content ?? loadContent()),
        profilesProvider.overrideWith(_FakeProfiles.new),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('cs'),
        home: child,
      ),
    );

class _FakeProfiles extends ProfilesNotifier {
  @override
  Future<List<Profile>> build() async => [anna, petr, twinA, twinB];
}

/// Lets the isolate in `Compute.synastry` finish.
Future<void> settle(WidgetTester t) async {
  // Let a route transition finish first, so the spinner of the new screen is in the tree.
  await t.pump();
  await t.pump(const Duration(milliseconds: 500));
  for (var i = 0; i < 100; i++) {
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await t.pump();
    if (find.byType(CircularProgressIndicator).evaluate().isEmpty) break;
  }
  await t.pumpAndSettle();
}

void bigScreen(WidgetTester t) {
  t.view.physicalSize = const Size(1170, 2532);
  t.view.devicePixelRatio = 3;
  addTearDown(t.view.reset);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({'onboardingDone': true}));

  test('reading shows each text once with all its facts', () {
    final s = Synastry.compute(Chart.compute(anna.birth), Chart.compute(petr.birth));
    final sections = synastrySections(s, markedContent());
    expect(sections.map((x) => x.id), ['aspects', 'points', 'houses']);
    final keys = [for (final x in sections) for (final i in x.items) i.key];
    expect(keys.toSet(), hasLength(keys.length));
    expect(sections.expand((x) => x.items).every((i) => i.entry != null), isTrue);
  });

  testWidgets('picker → bi-wheel, tables and reading', (t) async {
    bigScreen(t);
    await t.pumpWidget(wrap(const SynastryScreen()));
    await t.pumpAndSettle();
    expect(find.text('Typ vztahu'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, 'Rodič a dítě'), findsOneWidget);
    await t.tap(find.text('Porovnat'));
    await settle(t);
    expect(find.text('Anna a Petr'), findsOneWidget);
    expect(find.text('Vnitřní kruh: Anna · vnější kruh: Petr'), findsOneWidget);
    await t.tap(find.text('Tabulky'));
    await t.pumpAndSettle();
    expect(find.text('Aspekty mezi vámi'), findsOneWidget);
    await t.tap(find.text('Výklad'));
    await t.pumpAndSettle();
    expect(find.text('Aspekty mezi planetami'), findsOneWidget);
    expect(find.text('Text pro toto postavení zatím chybí.'), findsWidgets);
  });

  for (final r in Relationship.values) {
    testWidgets('partner layer for ${r.name}: ${r == Relationship.partner ? 'shown' : 'never shown'}', (t) async {
      bigScreen(t);
      await t.pumpWidget(wrap(SynastryResultScreen(anna, petr, r), content: markedContent()));
      await settle(t);
      await t.tap(find.text('Výklad'));
      await t.pumpAndSettle();
      final marks = find.textContaining(partnerMark);
      if (r == Relationship.partner) {
        expect(marks, findsWidgets);
        expect(find.text('Partnerský dovětek'), findsWidgets);
      } else {
        expect(find.textContaining('Mezi vámi'), findsWidgets);
        expect(marks, findsNothing);
      }
      // A row in the table opens the same text in a sheet.
      await t.tap(find.text('Tabulky'));
      await t.pumpAndSettle();
      await t.tap(find.byType(ListTile).first);
      await t.pumpAndSettle();
      expect(find.textContaining(partnerMark), r == Relationship.partner ? findsWidgets : findsNothing);
    });
  }

  test('every showPartner argument in the app goes through Relationship.showsPartnerLayer', () {
    final uses = <String>[];
    for (final f in Directory('lib').listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'))) {
      for (final m in RegExp(r'showPartner:\s*([^,)\n]+)').allMatches(f.readAsStringSync())) {
        uses.add('${f.path}: ${m[1]!.trim()}');
      }
    }
    expect(uses, isNotEmpty);
    for (final u in uses) {
      // Pass-through of the parameter, or the getter defined as `relationship.showsPartnerLayer`.
      expect(u, anyOf(endsWith(': showPartner'), endsWith(': _partner')), reason: u);
    }
    final screen = File('lib/ui/synastry/synastry_screen.dart').readAsStringSync();
    expect(screen, contains('bool get _partner => relationship.showsPartnerLayer;'));
  });

  testWidgets('twins: card instead of ten conjunctions', (t) async {
    bigScreen(t);
    await t.pumpWidget(wrap(SynastryResultScreen(twinA, twinB, Relationship.siblings)));
    await settle(t);
    expect(find.text('Horoskopy jsou skoro stejné'), findsOneWidget);
    expect(find.textContaining('Narození dělí 25 min'), findsOneWidget);
    expect(find.textContaining('Ascendent se liší o'), findsOneWidget);
    await t.tap(find.text('Tabulky'));
    await t.pumpAndSettle();
    expect(find.text('Slunce (Ema) konjunkce Slunce (Ela)'), findsNothing);
    await t.tap(find.text('Proč jsou dvojčata různá').first);
    await t.pumpAndSettle();
    expect(find.textContaining('Dvojčata narozená pár minut po sobě'), findsOneWidget);
  });
}
