// Renders screens with real fonts into PNGs for the store page (not part of the gate):
//   flutter test test/screens --run-skipped   → ../run/screens/NN-<what>.png (1179×2556)
// Fictional profiles only (Jana, Petr); the people catalog is the bundled one.
@Tags(['screens'])
library;

import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:astro/data/profile.dart';
import 'package:astro/journal_state.dart';
import 'package:astro/l10n/app_localizations.dart';
import 'package:astro/logic/horary.dart';
import 'package:astro/state.dart';
import 'package:astro/ui/chart/chart_screen.dart';
import 'package:astro/ui/election_screen.dart';
import 'package:astro/ui/horary/horary_screens.dart';
import 'package:astro/ui/person_screen.dart';
import 'package:astro/ui/synastry/synastry_screen.dart';
import 'package:astro_core/astro_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../journal_test.dart' show MemoryJournalStore, MemoryVault;
import '../logic_test.dart' show loadContent;

const jana = Profile(
  id: 'jana',
  name: 'Jana',
  birth: BirthData(
    moment: LocalMoment(year: 2000, month: 1, day: 1, hour: 13, minute: 0, zone: 'Europe/Prague'),
    lat: 50.0833,
    lon: 14.4167,
    placeName: 'Praha',
  ),
);

const petr = Profile(
  id: 'petr',
  name: 'Petr',
  birth: BirthData(
    moment: LocalMoment(year: 1998, month: 6, day: 14, hour: 7, minute: 40, zone: 'Europe/Prague'),
    lat: 49.1951,
    lon: 16.6068,
    placeName: 'Brno',
  ),
);

class _Profiles extends ProfilesNotifier {
  @override
  Future<List<Profile>> build() async => [jana, petr];
}

Future<void> _font(String family, String path) async {
  final loader = FontLoader(family)..addFont(Future.value(ByteData.sublistView(File(path).readAsBytesSync())));
  await loader.load();
}

final _shot = GlobalKey();
late Directory _tmp;

Widget _app(Widget home) => RepaintBoundary(
      key: _shot,
      child: ProviderScope(
        overrides: [
          contentProvider.overrideWith((ref) async => loadContent()),
          profilesProvider.overrideWith(_Profiles.new),
          journalStoreProvider.overrideWithValue(MemoryJournalStore()),
          horaryStoreProvider.overrideWithValue(HoraryStore(vault: MemoryVault(), dir: () async => _tmp)),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('cs'),
          home: home,
        ),
      ),
    );

void main() {
  setUpAll(() async {
    WidgetsApp.debugAllowBannerOverride = false;
    _tmp = Directory.systemTemp.createTempSync('astro-screens');
    await _font('Roboto', 'assets/fonts/NotoSans-Regular.ttf');
    await _font('NotoSansSymbols', 'assets/fonts/NotoSansSymbols-Regular.ttf');
    await _font('NotoSansSymbols2', 'assets/fonts/NotoSansSymbols2-Regular.ttf');
    await _font('MaterialIcons',
        '${Platform.environment['FLUTTER_ROOT']}/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf');
  });
  tearDownAll(() => _tmp.deleteSync(recursive: true));
  setUp(() => SharedPreferences.setMockInitialValues({'onboardingDone': true}));

  void phone(WidgetTester t) {
    t.view.physicalSize = const Size(1179, 2556);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
  }

  /// Lets isolates finish: real time passes while "Počítám…" or a spinner is on screen.
  Future<void> settle(WidgetTester t) async {
    await t.pump();
    await t.pump(const Duration(milliseconds: 500));
    for (var i = 0; i < 600; i++) {
      final busy = find.textContaining('Počítám').evaluate().isNotEmpty ||
          find.byType(CircularProgressIndicator).evaluate().isNotEmpty;
      if (!busy) break;
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 250)));
      await t.pump(const Duration(milliseconds: 50));
    }
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 500)));
    await t.pumpAndSettle();
  }

  Future<void> save(WidgetTester t, String name) async {
    final boundary = _shot.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    await t.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 3);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      File('../run/screens/$name.png')
        ..parent.createSync(recursive: true)
        ..writeAsBytesSync(bytes!.buffer.asUint8List());
    });
  }

  Future<void> chart(WidgetTester t, [String tab = '']) async {
    phone(t);
    await t.pumpWidget(_app(const ChartScreen(jana)));
    await settle(t);
    if (tab.isNotEmpty) {
      await t.tap(find.text(tab).first);
      await settle(t);
    }
  }

  testWidgets('01 overview', (t) async {
    await chart(t);
    await save(t, '01-overview');
  });

  testWidgets('02 tables', (t) async {
    await chart(t, 'Tabulky');
    await save(t, '02-tables');
  });

  testWidgets('03 reading', (t) async {
    await chart(t, 'Výklad');
    await save(t, '03-reading');
  });

  testWidgets('04 transits', (t) async {
    await chart(t, 'Tranzity');
    await save(t, '04-transits');
  });

  testWidgets('05 aspect pattern and fixed stars on the wheel', (t) async {
    await chart(t);
    await t.tap(find.byType(Switch).first);
    await t.tap(find.widgetWithText(ChoiceChip, 'T-kvadrát (pevný)'));
    await settle(t);
    await save(t, '05-patterns');
  });

  testWidgets('06 day by hours: Moon and planetary hours', (t) async {
    await chart(t, 'Tranzity');
    await t.tap(find.text('Den po hodinách'));
    await settle(t);
    await save(t, '06-hours');
  });

  testWidgets('07 progressions', (t) async {
    await chart(t, 'Tranzity');
    await t.tap(find.text('Progrese'));
    await settle(t);
    await save(t, '07-progressions');
  });

  testWidgets('08 synastry', (t) async {
    phone(t);
    await t.pumpWidget(_app(const SynastryScreen()));
    await settle(t);
    await t.tap(find.text('Porovnat'));
    await settle(t);
    await save(t, '08-synastry');
  });

  testWidgets('09 election', (t) async {
    phone(t);
    await t.pumpWidget(_app(const ElectionScreen()));
    await settle(t);
    // Working hours 8–18: drag both thumbs of the range slider.
    final slider = find.byType(RangeSlider);
    await t.ensureVisible(slider);
    await t.pumpAndSettle();
    final r = t.getRect(slider);
    const pad = 24.0;
    final w = r.width - 2 * pad;
    await t.dragFrom(Offset(r.left + pad, r.center.dy), Offset(w * 8 / 24, 0));
    await t.pumpAndSettle();
    await t.dragFrom(Offset(r.right - pad, r.center.dy), Offset(-w * 6 / 24, 0));
    await t.pumpAndSettle();
    expect(find.text('Hodiny dne: 8–18'), findsOneWidget);
    final search = find.text('Hledat');
    await t.ensureVisible(search);
    await t.pumpAndSettle();
    await t.tap(search);
    await settle(t);
    final header = find.textContaining(RegExp('nejvhodnější okna|neprošlo žádné okno'));
    await t.ensureVisible(header);
    await t.pumpAndSettle();
    await save(t, '09-election');
  });

  testWidgets('10 horary question', (t) async {
    phone(t);
    final book = HoraryBook.fromJson(
        (jsonDecode(File('assets/rules/horary.json').readAsStringSync()) as Map).cast<String, Object?>());
    // The first moment of a fixed day whose verdict is a "yes" with a timing, so the
    // shot shows every part of the answer.
    final place = jana.residencePlace;
    late DateTime at;
    late HoraryQuestion q;
    late HoraryJudgement j;
    for (var at0 = DateTime.utc(2026, 11, 19, 7);; at0 = at0.add(const Duration(minutes: 10))) {
      at = at0;
      q = HoraryQuestion(jdUt: jdFromDateTimeUtc(at), place: place, topic: 'career', person: 'self');
      j = HoraryEngine.judge(q, book);
      if ((j.verdict?.id.startsWith('yes') ?? false) && j.timing != null) break;
      if (at0.isAfter(DateTime.utc(2026, 11, 25))) fail('no "yes" with a timing found');
    }
    final record = HoraryRecord.question(
      id: 'q1',
      createdAt: at,
      text: 'Vezmou mě na tu novou práci?',
      topic: 'career',
      jdUt: q.jdUt,
      place: place,
      verdict: j.verdict?.id,
    );
    await t.pumpWidget(_app(HoraryResultScreen(jana, record, judgement: j)));
    await settle(t);
    await save(t, '10-horary');
  });

  testWidgets('11 catalog check of defining events', (t) async {
    phone(t);
    await t.pumpWidget(_app(const CatalogCheckScreen()));
    await settle(t);
    await save(t, '11-catalog');
  });
}
