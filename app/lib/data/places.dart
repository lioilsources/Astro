import 'package:flutter/services.dart';

class Place {
  final String name;
  final String folded;
  final String country;
  final double lat;
  final double lon;
  final String zone;
  final int population;

  /// Other folded names (English, Slovak…) that should find the place too.
  final List<String> aliases;
  const Place(this.name, this.folded, this.country, this.lat, this.lon, this.zone, this.population, [this.aliases = const []]);

  static Place parse(String line) {
    final p = line.split('\t');
    return Place(p[0], p[1], p[2], double.parse(p[3]), double.parse(p[4]), p[5], int.tryParse(p[6]) ?? 0,
        p.length > 7 && p[7].isNotEmpty ? p[7].split('|') : const []);
  }
  @override
  String toString() => '$name ($country)';
}

/// Removes Czech/Slovak and common Latin diacritics and lowercases.
String fold(String s) {
  const from = 'áäčďéěëíĺľňóôöŕřšťúůüýžÁÄČĎÉĚËÍĹĽŇÓÔÖŔŘŠŤÚŮÜÝŽàâãåæçèêìîïñòõøùûÿßłńśźżąę';
  const to = 'aacdeeeillnooorrstuuuyzaacdeeeillnooorrstuuuyzaaaaaceeiiinoooouuysslnszzae';
  final b = StringBuffer();
  for (final r in s.toLowerCase().runes) {
    final ch = String.fromCharCode(r);
    final i = from.indexOf(ch);
    b.write(i >= 0 ? to[i] : ch);
  }
  return b.toString();
}

/// Offline gazetteer from GeoNames (CC BY 4.0), sorted by population.
class PlaceIndex {
  final List<Place> places;
  const PlaceIndex(this.places);

  static Future<PlaceIndex> load(AssetBundle bundle) async {
    final raw = await bundle.loadString('assets/data/places.tsv');
    final out = <Place>[];
    for (final line in raw.split('\n')) {
      if (line.isEmpty || line.startsWith('#')) continue;
      out.add(Place.parse(line));
    }
    return PlaceIndex(out);
  }

  /// Prefix matches first (Czech and Slovak places preferred), then substring matches.
  List<Place> search(String query, {int limit = 20}) {
    final q = fold(query.trim());
    if (q.length < 2) return const [];
    final prefix = <Place>[], inner = <Place>[];
    for (final p in places) {
      if (p.folded.startsWith(q) || p.aliases.any((a) => a.startsWith(q))) {
        prefix.add(p);
      } else if (inner.length < limit && p.folded.contains(q)) {
        inner.add(p);
      }
    }
    // Exact names first; then population, Czech and Slovak places weighted ×20.
    double score(Place p) => p.population * ((p.country == 'CZ' || p.country == 'SK') ? 20.0 : 1.0) + 1;
    prefix.sort((a, b) {
      final exact = (b.folded == q || b.aliases.contains(q) ? 1 : 0).compareTo(a.folded == q || a.aliases.contains(q) ? 1 : 0);
      return exact != 0 ? exact : score(b).compareTo(score(a));
    });
    return [...prefix, ...inner].take(limit).toList();
  }
}
