import 'package:astro_core/content.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../l10n/app_localizations.dart';
import '../ui/format.dart';

/// A hard passage as a framed block headed by its topics in Czech, so it can be
/// found in a long PDF (shared by the reading and the pair guide PDFs).
pw.Widget hardPassageBlock(AppLocalizations l, HardPassage h) => pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 8),
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey600, width: 0.7)),
      child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Text(l.hardPassageTitle(l.topics(h.topics)), style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 4),
        pw.Text(h.text),
      ]),
    );
