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
    for (final e in (r['events'] as List? ?? const []).cast<Map>()) {
      if (!date.hasMatch(e['date'] as String? ?? '')) err('event date must be YYYY-MM-DD');
      if ((e['label'] as String? ?? '').isEmpty) err('event label required');
      if ((e['source'] as String? ?? '').isEmpty) err('event source required');
    }
  }
  return errors;
}
