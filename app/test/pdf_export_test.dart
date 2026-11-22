import 'package:astro/export/pdf_export.dart';
import 'package:astro/l10n/app_localizations.dart';
import 'package:astro/ui/format.dart';
import 'package:astro_core/astro_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'synastry_test.dart' show anna, markedContent;

void main() {
  test('hard passages are headed by Czech topic names, not ids', () async {
    final l = await AppLocalizations.delegate.load(const Locale('cs'));
    expect(l.hardPassageTitle(l.topics(['illness', 'mental_crisis'])), 'Těžké téma: nemoc, duševní krize');
    expect(l.hardPassageTitle(l.topics(['death', 'loss'])), 'Těžké téma: smrt, ztráta');
  });

  testWidgets('reading PDF builds with the bundled fonts', (t) async {
    final l = await AppLocalizations.delegate.load(const Locale('cs'));
    final bytes = await t.runAsync(() => buildReadingPdf(l, anna, Chart.compute(anna.birth), markedContent()));
    expect(bytes!.length, greaterThan(1000));
  });
}
