import 'dart:io';

import 'package:astro_core/astro_core.dart';
import 'package:astro_core/content.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../data/content_repository.dart';
import '../l10n/app_localizations.dart';
import '../logic/filter.dart';
import '../ui/format.dart';
import '../ui/synastry/pair_names.dart';

/// "Sdílet průvodce" (plan R9 6.2): the guide and the periods as PDF, as shown
/// under the current filter (owner decision 29: it goes to the other person).
Future<void> sharePairPdf(AppLocalizations l, PairNames names, PairGuide guide, PairTimeline timeline, ContentRepository content,
    ContentFilter filter,
    {required Relationship relationship, required double now}) async {
  final bytes = await buildPairPdf(l, names, guide, timeline, content, filter, relationship: relationship, now: now);
  final dir = await getTemporaryDirectory();
  final f = File('${dir.path}/pruvodce-vztahem.pdf');
  await f.writeAsBytes(bytes, flush: true);
  await SharePlus.instance.share(ShareParams(
    files: [XFile(f.path, mimeType: 'application/pdf')],
    subject: l.synastryPairTitle(names.first, names.second),
  ));
}

Future<Uint8List> buildPairPdf(AppLocalizations l, PairNames names, PairGuide guide, PairTimeline timeline, ContentRepository content,
    ContentFilter filter,
    {required Relationship relationship, required double now}) async {
  final regular = pw.Font.ttf(await rootBundle.load('assets/fonts/NotoSans-Regular.ttf'));
  final bold = pw.Font.ttf(await rootBundle.load('assets/fonts/NotoSans-Bold.ttf'));
  final doc = pw.Document(theme: pw.ThemeData.withFont(base: regular, bold: bold));
  final showPartner = relationship.showsPartnerLayer;
  final words = pairPdfEntries(guide, timeline, content, now: now);

  List<pw.Widget> entry(String heading, ContentEntry e, {bool shadowFirst = false}) {
    final f = filter.apply(e);
    final shadow = f.showShadow ? [pw.Paragraph(text: '${l.shadowTitle}: ${e.shadow}')] : const <pw.Widget>[];
    return [
      pw.Header(level: 2, text: heading),
      if (shadowFirst) ...shadow,
      pw.Paragraph(text: e.text),
      if (!shadowFirst) ...shadow,
      if (e.advice.isNotEmpty) pw.Paragraph(text: '${l.adviceTitle}: ${e.advice}'),
      if (showPartner && e.partner.isNotEmpty) pw.Paragraph(text: '${l.synastryPartnerTitle}: ${e.partner}'),
      for (final h in f.visibleHard) pw.Paragraph(text: '[${l.topics(h.topics)}] ${h.text}'),
      if (f.hiddenCount > 0) pw.Paragraph(text: l.hiddenPassages(f.hiddenCount, l.topics(f.hiddenTopics))),
    ];
  }

  doc.addPage(pw.MultiPage(
    pageFormat: PdfPageFormat.a4,
    build: (c) => [
      pw.Header(level: 0, text: l.synastryPairTitle(names.first, names.second)),
      pw.Text(l.relationshipName(relationship.name)),
      pw.Paragraph(text: l.pairPdfIntro),
      for (final MapEntry(key: area, value: n) in guide.overview.entries)
        pw.Text('${l.pairArea(area.name)}: ${l.pairAreaCounts(n.supportive, n.straining)}'),
      for (final w in words) ...[
        if (w.chapter != null) pw.Header(level: 1, text: l.pairChapter(w.chapter!)),
        if (w.entry != null) ...entry(w.title(l, names), w.entry!, shadowFirst: w.shadowFirst),
      ],
    ],
  ));
  return doc.save();
}

/// One item of the PDF: a chapter heading or a text with its title.
class PairPdfItem {
  /// Chapter id ([GuideChapterId.name]) of a heading.
  final String? chapter;
  final ContentEntry? entry;
  final GuideBlock? block;
  final PairPeriod? period;
  final bool shadowFirst;
  const PairPdfItem({this.chapter, this.entry, this.block, this.period, this.shadowFirst = false});

  String title(AppLocalizations l, PairNames names) {
    if (block != null) return names.block(l, block!);
    if (period != null) return '${names.period(l, period!)} (${l.periodRange(monthYear(period!.start), monthYear(period!.end))})';
    return entry!.title;
  }
}

/// What goes into the PDF, in order: full texts of every chapter (links left out,
/// each text once) and the coming straining periods. Missing texts are skipped.
List<PairPdfItem> pairPdfEntries(PairGuide guide, PairTimeline timeline, ContentRepository content, {required double now}) {
  final out = <PairPdfItem>[];
  final seen = <String>{};
  for (final c in guide.chapters) {
    if (c.id == GuideChapterId.overview) continue;
    out.add(PairPdfItem(chapter: c.id.name));
    final intro = content[c.introKey];
    if (intro != null) out.add(PairPdfItem(entry: intro));
    if (c.id == GuideChapterId.periods) {
      for (final p in timeline.periods) {
        if (!p.isStraining || p.end < now) continue;
        final e = content[pairPeriodKey(p)];
        if (e != null) out.add(PairPdfItem(entry: e, period: p));
      }
      continue;
    }
    for (final b in c.blocks) {
      if (b.linkOnly || !seen.add('${b.key}|${b.need?.ofFirst}')) continue;
      final e = content[b.key];
      if (e != null) out.add(PairPdfItem(entry: e, block: b, shadowFirst: c.id == GuideChapterId.cautions));
    }
  }
  return out;
}
