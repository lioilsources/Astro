// Renders screens with real fonts into PNGs for a visual check (not part of the gate):
//   flutter test test/screens --update-goldens   → ../run/screens/*.png
@Tags(['screens'])
library;

import 'dart:io';

import 'package:astro/ui/chart/chart_screen.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../widget_test.dart' show wrap, profile;

Future<void> _font(String family, String path) async {
  final loader = FontLoader(family)..addFont(Future.value(ByteData.sublistView(File(path).readAsBytesSync())));
  await loader.load();
}

void main() {
  setUpAll(() async {
    await _font('Roboto', 'assets/fonts/NotoSans-Regular.ttf');
    await _font('NotoSansSymbols', 'assets/fonts/NotoSansSymbols-Regular.ttf');
    await _font('NotoSansSymbols2', 'assets/fonts/NotoSansSymbols2-Regular.ttf');
  });
  setUp(() => SharedPreferences.setMockInitialValues({'onboardingDone': true}));

  Future<void> shot(WidgetTester t, String tab, String name) async {
    t.view.physicalSize = const Size(1179, 2556);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    await t.pumpWidget(wrap(const ChartScreen(profile)));
    await t.pumpAndSettle();
    if (tab.isNotEmpty) {
      await t.tap(find.text(tab));
      await t.pumpAndSettle();
    }
    await t.runAsync(() => Future<void>.delayed(const Duration(seconds: 3)));
    await t.pumpAndSettle();
    await expectLater(find.byType(ChartScreen), matchesGoldenFile('../../../run/screens/$name.png'));
  }

  testWidgets('overview', (t) => shot(t, '', 'overview'));
  testWidgets('tables', (t) => shot(t, 'Tabulky', 'tables'));
  testWidgets('reading', (t) => shot(t, 'Výklad', 'reading'));
  testWidgets('transits', (t) => shot(t, 'Tranzity', 'transits'));
}
