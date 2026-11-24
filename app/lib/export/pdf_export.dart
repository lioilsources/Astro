import 'package:astro_core/astro_core.dart';
import 'package:flutter/material.dart' show BuildContext;
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../data/content_repository.dart';
import '../data/profile.dart';
import '../l10n/app_localizations.dart';
import '../logic/reading.dart';
import 'pdf_blocks.dart';
import '../platform/share_bytes.dart';

/// "Sdílet celý výklad": the unfiltered reading as PDF, without opening hidden
/// passages on screen (plan 5.1). Meant to be handed to a therapist.
Future<void> shareFullReading(BuildContext context, Profile profile, Chart chart, ContentRepository content) async {
  final bytes = await buildReadingPdf(AppLocalizations.of(context), profile, chart, content);
  await shareBytes(bytes, 'vyklad-${profile.id}.pdf', 'application/pdf', subject: profile.name);
}

Future<Uint8List> buildReadingPdf(AppLocalizations l, Profile profile, Chart chart, ContentRepository content) async {
  final regular = pw.Font.ttf(await rootBundle.load('assets/fonts/NotoSans-Regular.ttf'));
  final bold = pw.Font.ttf(await rootBundle.load('assets/fonts/NotoSans-Bold.ttf'));
  final doc = pw.Document(theme: pw.ThemeData.withFont(base: regular, bold: bold));
  final m = profile.birth.moment;
  final items = readingItems(chart, content).where((i) => i.entry != null);
  doc.addPage(pw.MultiPage(
    pageFormat: PdfPageFormat.a4,
    build: (c) => [
      pw.Header(level: 0, text: profile.name),
      pw.Text('${m.day}. ${m.month}. ${m.year}${m.hour != null ? ' ${m.hour}:${(m.minute ?? 0).toString().padLeft(2, '0')}' : ''}'
          '${profile.birth.placeName != null ? ', ${profile.birth.placeName}' : ''}'),
      pw.Text(l.readingPdfIntro),
      pw.SizedBox(height: 12),
      for (final i in items) ...[
        pw.Header(level: 2, text: i.entry!.title),
        pw.Paragraph(text: i.entry!.text),
        if (i.entry!.shadow.isNotEmpty) pw.Paragraph(text: '${l.shadowTitle}: ${i.entry!.shadow}'),
        for (final h in i.entry!.hard) hardPassageBlock(l, h),
      ],
    ],
  ));
  return doc.save();
}
