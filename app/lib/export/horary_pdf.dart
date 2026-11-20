import 'dart:io';

import 'package:astro_core/astro_core.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../data/content_repository.dart';
import '../l10n/app_localizations.dart';
import '../ui/format.dart';
import '../ui/horary/horary_screens.dart' show horaryTimingText;

/// One horary question as PDF. The question text goes in only when the user
/// ticks it explicitly (plan 10.8, privacy).
Future<void> shareHoraryPdf(AppLocalizations l, HoraryRecord r, HoraryJudgement j, ContentRepository content, {required bool includeText}) async {
  final bytes = await buildHoraryPdf(l, r, j, content, includeText: includeText);
  final dir = await getTemporaryDirectory();
  final f = File('${dir.path}/otazka-${r.id}.pdf');
  await f.writeAsBytes(bytes, flush: true);
  await SharePlus.instance.share(ShareParams(files: [XFile(f.path, mimeType: 'application/pdf')], subject: l.horaryTopicName(r.topic ?? '')));
}

Future<Uint8List> buildHoraryPdf(AppLocalizations l, HoraryRecord r, HoraryJudgement j, ContentRepository content, {required bool includeText}) async {
  final regular = pw.Font.ttf(await rootBundle.load('assets/fonts/NotoSans-Regular.ttf'));
  final bold = pw.Font.ttf(await rootBundle.load('assets/fonts/NotoSans-Bold.ttf'));
  final doc = pw.Document(theme: pw.ThemeData.withFont(base: regular, bold: bold));
  final place = j.question.place;
  final when = localTime(j.question.jdUt, place);
  String names(List<Rule> rules) => rules.isEmpty ? '—' : rules.map((x) => l.horaryTestimony(x.id)).join(', ');
  doc.addPage(pw.MultiPage(
    pageFormat: PdfPageFormat.a4,
    build: (c) => [
      pw.Header(level: 0, text: l.horaryTopicName(r.topic ?? '')),
      if (includeText && (r.text ?? '').isNotEmpty) pw.Paragraph(text: '„${r.text}“'),
      pw.Text(l.horaryMoment(fmtDateTime(when), place.name ?? '${place.lat}, ${place.lon}')),
      pw.SizedBox(height: 8),
      if (j.verdict == null)
        pw.Paragraph(text: l.horaryNoVerdict)
      else ...[
        pw.Header(level: 1, text: l.horaryVerdictLine(l.horaryVerdictName(j.verdict!.id))),
        pw.Paragraph(text: l.horaryDisclaimer),
        pw.Paragraph(text: '${l.electionFor}: ${names(j.plus)}'),
        pw.Paragraph(text: '${l.electionAgainst}: ${names(j.minus)}'),
        if (j.timing != null) pw.Paragraph(text: horaryTimingText(l, j.timing!)),
        if (j.lost != null)
          pw.Paragraph(text: l.horaryLostLine(l.horaryDirection(j.lost!.bySign), l.sign(j.lost!.sign), l.horaryDirection(j.lost!.byHouse), j.lost!.house)),
      ],
      pw.Header(level: 2, text: l.horaryConsiderations),
      pw.Paragraph(text: j.considerations.isEmpty ? l.horaryConsiderationsNone : j.considerations.map((x) => l.horaryConsideration(x.id)).join(', ')),
      for (final x in [...j.plus, ...j.minus])
        if (content[x.textKey] case final e?) ...[pw.Header(level: 3, text: e.title), pw.Paragraph(text: e.text)],
    ],
  ));
  return doc.save();
}
