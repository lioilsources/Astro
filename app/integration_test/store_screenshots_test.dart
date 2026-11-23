// Screenshoty do App Store: profily, horoskop, výklad, tranzity, partnerský průvodce,
// horární otázka, katalog osobností. Appka je jen česky, proto jeden jazyk (cs);
// tool/store_screenshots.sh je zkopíruje i do en-US.
// Spouští tool/store_screenshots.sh (flutter drive na simulátoru); PNG ukládá
// test_driver/screenshot_driver.dart do SCREENSHOT_DIR.
// Jen smyšlené profily (Jana, Petr), nic se neukládá do zařízení.

import 'dart:convert';
import 'dart:io';

import 'package:astro/app.dart';
import 'package:astro/data/journal_store.dart';
import 'package:astro/data/pairs.dart';
import 'package:astro/data/profile.dart';
import 'package:astro/journal_state.dart';
import 'package:astro/logic/horary.dart';
import 'package:astro/pair_state.dart';
import 'package:astro/state.dart';
import 'package:astro/ui/horary/horary_screens.dart';
import 'package:astro_core/astro_core.dart';
import 'package:astro_core/journal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

class _Vault implements KeyVault {
  final values = <String, String>{};
  @override
  Future<String?> read(String name) async => values[name];
  @override
  Future<void> write(String name, String value) async => values[name] = value;
}

class _Pairs extends PairStore {
  @override
  Future<List<Pair>> load() async =>
      const [Pair(id: 'p1', firstId: 'jana', secondId: 'petr', relationship: Relationship.partner)];
  @override
  Future<void> save(List<Pair> pairs) async {}
}

class _Journal extends JournalStore {
  @override
  Future<Journal> load(String profileId) async => Journal();
  @override
  Future<void> save(String profileId, Journal j) async {}
  @override
  Future<void> delete(String profileId) async {}
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('store screenshots', (t) async {
    WidgetsApp.debugAllowBannerOverride = false;
    SharedPreferences.setMockInitialValues({'onboardingDone': true});
    final tmp = Directory.systemTemp.createTempSync('astro-shots');

    await t.pumpWidget(ProviderScope(
      overrides: [
        profilesProvider.overrideWith(_Profiles.new),
        pairStoreProvider.overrideWithValue(_Pairs()),
        journalStoreProvider.overrideWithValue(_Journal()),
        horaryStoreProvider.overrideWithValue(HoraryStore(vault: _Vault(), dir: () async => tmp)),
      ],
      child: const AstroApp(),
    ));
    await _settle(t);

    Future<void> shot(int n, String scene) async {
      await _settle(t);
      await binding.takeScreenshot('cs_${n}_$scene');
    }

    NavigatorState root() => Navigator.of(t.element(find.byType(HomeScreen, skipOffstage: false)));

    Future<void> back() async {
      root().pop();
      await _settle(t);
    }

    await shot(1, 'profiles');

    await t.tap(find.text('Jana').last);
    await shot(2, 'chart');
    await t.tap(find.text('Výklad').first);
    await shot(3, 'reading');
    await t.tap(find.text('Tranzity').first);
    await shot(4, 'transits');
    await back();

    await t.tap(find.text('Jana a Petr').first);
    await shot(5, 'pair');
    await back();

    // Horární otázka s odpovědí „ano“ a odhadem času, ať je vidět celý výsledek.
    final book = HoraryBook.fromJson(
        (jsonDecode(await rootBundle.loadString('assets/rules/horary.json')) as Map).cast<String, Object?>());
    final place = jana.residencePlace;
    late HoraryQuestion q;
    late HoraryJudgement j;
    late DateTime at;
    for (at = DateTime.utc(2026, 11, 19, 7);; at = at.add(const Duration(minutes: 10))) {
      q = HoraryQuestion(jdUt: jdFromDateTimeUtc(at), place: place, topic: 'career', person: 'self');
      j = HoraryEngine.judge(q, book);
      if ((j.verdict?.id.startsWith('yes') ?? false) && j.timing != null) break;
      if (at.isAfter(DateTime.utc(2026, 11, 25))) throw StateError('no "yes" with a timing found');
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
    root().push(MaterialPageRoute<void>(builder: (_) => HoraryResultScreen(jana, record, judgement: j)));
    await shot(6, 'horary');
    await back();

    await t.tap(find.text('Osobnosti').last);
    await _settle(t);
    // Kategorie Věda: Lovelaceová, Turing, Einstein… (abecední začátek „Všichni“ je nevhodný).
    final science = find.widgetWithText(ChoiceChip, 'Věda');
    await t.ensureVisible(science);
    await _settle(t);
    await t.tap(science);
    await _settle(t);
    if (!t.widget<ChoiceChip>(science).selected) throw StateError('kategorie Věda se nevybrala');
    await shot(7, 'people');

    await t.pumpWidget(const SizedBox());
    tmp.deleteSync(recursive: true);
  });
}

/// Real time passes while "Počítám…" or a spinner is on screen (max 60 s).
Future<void> _settle(WidgetTester t) async {
  Future<void> wait(int ms) async {
    final end = DateTime.now().add(Duration(milliseconds: ms));
    while (DateTime.now().isBefore(end)) {
      await t.pump(const Duration(milliseconds: 16));
    }
  }

  await wait(600);
  for (var i = 0; i < 240; i++) {
    final busy = find.textContaining('Počítám').evaluate().isNotEmpty ||
        find.byType(CircularProgressIndicator).evaluate().isNotEmpty ||
        find.byType(LinearProgressIndicator).evaluate().isNotEmpty;
    if (!busy) break;
    await wait(250);
  }
  await wait(800);
}
