import 'dart:io';

import 'package:astro_core/astro_core.dart';
import 'package:flutter/material.dart' show BuildContext;
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../data/content_repository.dart';
import '../data/profile.dart';
import '../logic/reading.dart';

/// "Sdílet celý výklad": the unfiltered reading as PDF, without opening hidden
/// passages on screen (plan 5.1). Meant to be handed to a therapist.
Future<void> shareFullReading(BuildContext context, Profile profile, Chart chart, ContentRepository content) async {
  final bytes = await buildReadingPdf(profile, chart, content);
  final dir = await getTemporaryDirectory();
  final f = File('${dir.path}/vyklad-${profile.id}.pdf');
  await f.writeAsBytes(bytes, flush: true);
  await SharePlus.instance.share(ShareParams(files: [XFile(f.path, mimeType: 'application/pdf')], subject: profile.name));
}

Future<Uint8List> buildReadingPdf(Profile profile, Chart chart, ContentRepository content) async {
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
      pw.Text('Úplný výklad bez filtru, včetně stinných stránek a těžkých témat. Jde o tradiční výklad postavení, ne o předpověď.'),
      pw.SizedBox(height: 12),
      for (final i in items) ...[
        pw.Header(level: 2, text: i.entry!.title),
        pw.Paragraph(text: i.entry!.text),
        if (i.entry!.shadow.isNotEmpty) pw.Paragraph(text: 'Stinná stránka: ${i.entry!.shadow}'),
        for (final h in i.entry!.hard) pw.Paragraph(text: '[${h.topics.join(', ')}] ${h.text}'),
      ],
    ],
  ));
  return doc.save();
}
