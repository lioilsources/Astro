/// Validation of the people catalog (Prompts/KATALOG-osobnosti.md, plan 4.3).
/// Only records with a source may ship; no birth time without a source.
const reliabilityGrades = ['AA', 'A', 'B', 'C', 'DD', 'X'];
const peopleCategories = ['history', 'politics', 'military', 'science', 'art', 'music', 'film', 'celebrity', 'football', 'hockey', 'sport', 'business', 'religion', 'literature'];

List<String> validatePeople(List<Map<String, dynamic>> records) {
  final errors = <String>[];
  final ids = <String>{};
  final date = RegExp(r'^-?\d{1,4}-\d{2}-\d{2}$');
  final time = RegExp(r'^\d{2}:\d{2}$');
  for (final r in records) {
    final id = r['id'] as String? ?? '?';
    void err(String m) => errors.add('$id: $m');
    if (!ids.add(id)) err('duplicate id');
    if ((r['name'] as String? ?? '').isEmpty) err('no name');
    if (r['living'] is! bool) err('living must be true/false');
    final cats = (r['categories'] as List? ?? const []).cast<String>();
    if (cats.isEmpty) err('no category');
    for (final c in cats) {
      if (!peopleCategories.contains(c)) err('unknown category $c');
    }
    final rel = r['reliability'] as String?;
    if (!reliabilityGrades.contains(rel)) err('reliability must be one of ${reliabilityGrades.join(', ')}');
    final src = r['source'] as Map?;
    if (src == null || (src['note'] as String? ?? '').isEmpty || (src['url'] as String? ?? '').isEmpty) err('source note and url are required');
    final b = r['birth'] as Map?;
    if (b == null) {
      err('no birth');
      continue;
    }
    if (!date.hasMatch(b['date'] as String? ?? '')) err('birth.date must be YYYY-MM-DD');
    if (!const ['julian', 'gregorian'].contains(b['calendar'])) err('birth.calendar must be julian or gregorian');
    if (b['lat'] is! num || b['lon'] is! num) err('birth.lat/lon required');
    final t = b['time'] as String?;
    if (t != null) {
      if (!time.hasMatch(t)) err('birth.time must be HH:MM');
      if (!const ['zone', 'ut', 'lmt'].contains(b['time_basis'])) err('birth.time_basis must be zone, ut or lmt');
      if (b['time_basis'] == 'zone' && (b['zone'] as String? ?? '').isEmpty) err('zone time needs an IANA zone');
      if (rel == 'X') err('reliability X means no time, but a time is given');
    } else if (rel != 'X' && rel != 'DD') {
      err('no birth time → reliability must be X');
    }
    final birthDate = b['date'] as String? ?? '';
    for (final e in (r['events'] as List? ?? const []).cast<Map>()) {
      errors.addAll(validateEvent(e.cast<String, dynamic>(), birthDate).map((m) => '$id: $m'));
    }
  }
  return errors;
}

/// Event kinds (Prompts/KATALOG-osobnosti.md, oddíl 6). Records written before the
/// `type` field are accepted without one.
const eventTypes = [
  'office', 'election', 'coronation', 'abdication', 'award', 'title', 'record', 'work', 'premiere',
  'publication', 'discovery', 'breakthrough', 'battle', 'treaty', 'founding', 'scandal', 'arrest',
  'trial', 'assassination_attempt', 'resignation', 'event', 'marriage', 'club', 'death', 'other',
];

const _months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];

/// Day-precise dates written in an English sentence ("18 June 1815", "June 18, 1815") as YYYY-MM-DD.
Set<String> datesWrittenIn(String text) {
  final m = _months.join('|');
  String iso(String y, String mo, String d) =>
      '${int.parse(y).toString().padLeft(4, '0')}-${(_months.indexOf(mo) + 1).toString().padLeft(2, '0')}-${int.parse(d).toString().padLeft(2, '0')}';
  return {
    for (final x in RegExp('\\b(\\d{1,2}) ($m),? (\\d{3,4})\\b').allMatches(text)) iso(x[3]!, x[2]!, x[1]!),
    for (final x in RegExp('\\b($m) (\\d{1,2}),? (\\d{3,4})\\b').allMatches(text)) iso(x[3]!, x[1]!, x[2]!),
  };
}

/// True for a real calendar day (Gregorian or Julian; 29 February allowed in every 4th year).
bool _realDay(String s) {
  final m = RegExp(r'^(-?\d{1,4})-(\d{2})-(\d{2})$').firstMatch(s);
  if (m == null) return false;
  final y = int.parse(m[1]!), mo = int.parse(m[2]!), d = int.parse(m[3]!);
  if (mo < 1 || mo > 12 || d < 1) return false;
  const len = [31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
  if (mo == 2 && d == 29) return y % 4 == 0;
  return d <= len[mo - 1];
}

/// Checks one event: day-precise date within the life, label, source; a defining event needs a
/// link, and one read from Wikipedia carries the sentence that writes its date.
List<String> validateEvent(Map<String, dynamic> e, String birthDate) {
  final errors = <String>[];
  final d = e['date'] as String? ?? '';
  final label = e['label'] as String? ?? '';
  void err(String m) => errors.add('event ${d.isEmpty ? '?' : d} $label: $m');
  if (!_realDay(d)) err('date must be a real day YYYY-MM-DD');
  if (birthDate.isNotEmpty && d.isNotEmpty && d.compareTo(birthDate) < 0) err('event before birth');
  if (label.isEmpty) err('label required');
  final source = e['source'] as String? ?? '';
  if (source.isEmpty) err('source required');
  final type = e['type'];
  if (type != null && !eventTypes.contains(type)) err('unknown type $type');
  final defining = e['defining'];
  if (defining != null && defining is! bool) err('defining must be true/false');
  if (defining == true) {
    if (type == null) err('a defining event needs a type');
    final url = e['url'] as String? ?? '';
    if (!url.startsWith('https://')) err('a defining event needs a source url');
  }
  if (source.startsWith('Wikipedia')) {
    final quote = e['quote'] as String? ?? '';
    final written = e['date_julian'] as String? ?? d;
    if (quote.isEmpty) {
      err('a Wikipedia event needs the quoted sentence');
    } else if (!datesWrittenIn(quote).contains(written)) {
      err('the quoted sentence does not write the date $written');
    }
    if (!(e['url'] as String? ?? '').startsWith('https://en.wikipedia.org/wiki/')) err('a Wikipedia event needs the article url');
  } else if (source.startsWith('Wikidata') && !RegExp(r'^Wikidata Q\d+ P\d+( Q\d+)?$').hasMatch(source)) {
    err('Wikidata source must be "Wikidata <QID> <property> [<value QID>]"');
  }
  if (e['date_julian'] != null && !_realDay(e['date_julian'] as String)) err('date_julian must be YYYY-MM-DD');
  return errors;
}

/// Number of defining events per record id (for the coverage report of the builder).
Map<String, int> definingCounts(List<Map<String, dynamic>> records) => {
      for (final r in records)
        r['id'] as String: (r['events'] as List? ?? const []).cast<Map>().where((e) => e['defining'] == true).length,
    };
