import 'dart:io';

import 'package:astro_core/astro_core.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// One calendar event of an election window.
class IcsEvent {
  final double startJd, endJd;
  final String summary;
  final String description;
  const IcsEvent(this.startJd, this.endJd, this.summary, this.description);
}

String _utc(double jd) {
  final d = dateTimeUtcFromJd(jd);
  String two(int v) => v.toString().padLeft(2, '0');
  return '${d.year}${two(d.month)}${two(d.day)}T${two(d.hour)}${two(d.minute)}${two(d.second)}Z';
}

/// RFC 5545 text escaping.
String _esc(String s) => s.replaceAll('\\', '\\\\').replaceAll(';', '\\;').replaceAll(',', '\\,').replaceAll('\n', '\\n');

/// Lines longer than 75 octets are folded (RFC 5545 §3.1).
String _fold(String line) {
  final out = StringBuffer();
  var count = 0;
  for (final r in line.runes) {
    final ch = String.fromCharCode(r);
    final n = ch.codeUnits.length == 1 && r < 0x80 ? 1 : (r < 0x800 ? 2 : (r < 0x10000 ? 3 : 4));
    if (count + n > 75) {
      out.write('\r\n ');
      count = 1;
    }
    out.write(ch);
    count += n;
  }
  return out.toString();
}

/// A VCALENDAR with one VEVENT per event, times in UTC.
String buildIcs(List<IcsEvent> events, {DateTime? now}) {
  final stamp = _utc(jdFromDateTimeUtc((now ?? DateTime.now()).toUtc()));
  final lines = [
    'BEGIN:VCALENDAR',
    'VERSION:2.0',
    'PRODID:-//Astro//Election//CS',
    'CALSCALE:GREGORIAN',
    for (final e in events) ...[
      'BEGIN:VEVENT',
      'UID:election-${e.startJd.toStringAsFixed(5)}-${e.endJd.toStringAsFixed(5)}@astro',
      'DTSTAMP:$stamp',
      'DTSTART:${_utc(e.startJd)}',
      'DTEND:${_utc(e.endJd)}',
      'SUMMARY:${_esc(e.summary)}',
      'DESCRIPTION:${_esc(e.description)}',
      'END:VEVENT',
    ],
    'END:VCALENDAR',
  ];
  return '${lines.map(_fold).join('\r\n')}\r\n';
}

/// Writes the calendar file and opens the share sheet.
Future<void> shareIcs(List<IcsEvent> events, String subject) async {
  final dir = await getTemporaryDirectory();
  final f = File('${dir.path}/termin.ics');
  await f.writeAsString(buildIcs(events));
  await SharePlus.instance.share(ShareParams(files: [XFile(f.path, mimeType: 'text/calendar')], subject: subject));
}
