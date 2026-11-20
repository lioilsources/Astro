import 'package:astro/app.dart';
import 'package:astro/data/profile.dart';
import 'package:astro/l10n/app_localizations.dart';
import 'package:astro/state.dart';
import 'package:astro/ui/chart/chart_screen.dart';
import 'package:astro/ui/chart/tables_tab.dart';
import 'package:astro_core/astro_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'logic_test.dart' show loadContent;

const profile = Profile(
  id: 'test',
  name: 'Test',
  birth: BirthData(
    moment: LocalMoment(year: 2000, month: 1, day: 1, hour: 12, minute: 0, basis: TimeBasis.ut),
    lat: 50.0833,
    lon: 14.4167,
    placeName: 'Praha',
  ),
);

Widget wrap(Widget child) => ProviderScope(
      overrides: [
        contentProvider.overrideWith((ref) async => loadContent()),
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
  Future<List<Profile>> build() async => [profile];
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({'onboardingDone': true}));

  testWidgets('onboarding offers both modes', (t) async {
    SharedPreferences.setMockInitialValues({});
    await t.pumpWidget(ProviderScope(overrides: [profilesProvider.overrideWith(_FakeProfiles.new)], child: const AstroApp()));
    await t.pumpAndSettle();
    expect(find.text('Zobrazovat všechno'), findsOneWidget);
    expect(find.text('Zapnout šetrný režim'), findsOneWidget);
  });

  testWidgets('chart screen renders overview, tables and reading', (t) async {
    t.view.physicalSize = const Size(1170, 2532);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    await t.pumpWidget(wrap(const ChartScreen(profile)));
    await t.pumpAndSettle();
    expect(find.textContaining('Slunce Kozoroh'), findsOneWidget);
    await t.tap(find.text('Tabulky'));
    await t.pumpAndSettle();
    expect(find.text('Pozice planet'), findsOneWidget);
    await t.tap(find.text('Výklad'));
    await t.pumpAndSettle();
    expect(find.text('Planety ve znameních'), findsOneWidget);
    expect(find.text('Slunce v Kozorohu'), findsOneWidget);
  });

  testWidgets('patterns: chip highlights the wheel, table row opens the sheet', (t) async {
    t.view.physicalSize = const Size(1170, 2532);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    await t.pumpWidget(wrap(const ChartScreen(profile)));
    await t.pumpAndSettle();
    // 2000-01-01 12:00 UT has a fixed T-square Moon–Saturn with Uranus at the apex.
    final chip = find.widgetWithText(ChoiceChip, 'T-kvadrát (pevný)');
    expect(chip, findsOneWidget);
    await t.tap(chip);
    await t.pumpAndSettle();
    expect(t.widget<ChoiceChip>(chip).selected, isTrue);

    await t.tap(find.text('Tabulky'));
    await t.pumpAndSettle();
    final row = find.descendant(of: find.byType(TablesTab), matching: find.text('T-kvadrát (pevný)'));
    await t.scrollUntilVisible(row, 300, scrollable: find.descendant(of: find.byType(TablesTab), matching: find.byType(Scrollable)).first);
    await t.tap(row);
    await t.pumpAndSettle();
    expect(find.text('Uran na vrcholu T-kvadrátu'), findsOneWidget);
    expect(find.text('Text pro toto postavení zatím chybí.'), findsWidgets);
  });
}
