import 'dart:io';

import 'package:astro/logic/horary.dart';
import 'package:astro/ui/ask_screen.dart';
import 'package:astro_core/astro_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'journal_test.dart' show MemoryVault;
import 'widget_test.dart' show wrap;

void main() {
  test('question log is stored encrypted; the question text never appears in clear', () async {
    final dir = Directory.systemTemp.createTempSync('r8-horary');
    addTearDown(() => dir.deleteSync(recursive: true));
    final vault = MemoryVault();
    final store = HoraryStore(vault: vault, dir: () async => dir);
    final at = DateTime.utc(2026, 5, 1, 9);
    final log = HoraryLog().append(
      HoraryRecord.question(
        id: 'q1',
        createdAt: at,
        text: 'Dostanu tu práci v Brně?',
        topic: 'career',
        jdUt: jdFromDateTimeUtc(at),
        place: const GeoLocation(lat: 49.195, lon: 16.608, name: 'Brno', zone: 'Europe/Prague'),
        verdict: 'yes',
      ),
      at,
    );
    await store.save('p1', log);
    final file = File('${dir.path}/${HoraryStore.pathOf('p1')}');
    final raw = file.readAsBytesSync();
    expect(String.fromCharCodes(raw).contains('Brně'), isFalse);
    expect(String.fromCharCodes(raw).contains('career'), isFalse);
    final back = await HoraryStore(vault: vault, dir: () async => dir).load('p1');
    expect(back.questionById('q1')!.text, 'Dostanu tu práci v Brně?');
    expect((await store.load('other')).records, isEmpty);
  });

  testWidgets('ask screen: horary mode with topic, person and derived house', (t) async {
    t.view.physicalSize = const Size(1170, 2532);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    await t.pumpWidget(wrap(const AskScreen()));
    await t.pumpAndSettle();
    await t.tap(find.text('Horární'));
    await t.pumpAndSettle();
    expect(find.text('Potvrdit otázku'), findsOneWidget);
    expect(find.text('Kariéra, místo'), findsOneWidget);
    expect(find.text('Dům věci: 10.'), findsOneWidget);
    expect(find.text('Já'), findsOneWidget);
    expect(find.text('Deník otázek'), findsOneWidget);
    expect(find.textContaining('verdikt nedává'), findsNothing);
  });
}
