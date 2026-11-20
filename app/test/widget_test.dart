import 'package:astro/app.dart';
import 'package:astro/data/profile.dart';
import 'package:astro/l10n/app_localizations.dart';
import 'package:astro/state.dart';
import 'package:astro/ui/chart/chart_screen.dart';
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

  testWidgets('transits show the Moon, void of course and planetary hours', (t) async {
    t.view.physicalSize = const Size(1170, 2532);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    await t.pumpWidget(wrap(const ChartScreen(profile)));
    await t.pumpAndSettle();
    await t.tap(find.text('Tranzity'));
    await t.pump();
    // Month data comes from isolates: let real time pass.
    for (var i = 0; i < 240 && find.text('Počítám…').evaluate().isNotEmpty; i++) {
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 500)));
      await t.pump();
    }
    expect(find.text('Počítám…'), findsNothing);
    final dayRuler = find.textContaining(RegExp(r'^Den (Slunce|Měsíce|Merkura|Venuše|Marsu|Jupitera|Saturnu)$'));
    await t.dragUntilVisible(dayRuler, find.byType(ListView).last, const Offset(0, -300));
    await t.tap(find.text('Den po hodinách'));
    await t.pumpAndSettle();
    expect(find.textContaining('Hodina '), findsWidgets);
  });
}
