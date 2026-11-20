import 'package:astro_core/astro_core.dart';
import 'package:astro_core/content.dart';

import '../data/content_repository.dart';

/// One text of a pair reading with every fact that leads to it
/// (Sun–Moon and Moon–Sun share `synastry/sun/moon/…`).
class PairReadingItem {
  final String key;
  final ContentEntry? entry;
  final List<Factor> facts;
  const PairReadingItem(this.key, this.entry, this.facts);

  double get weight => facts.map((f) => f.weight).reduce((a, b) => a > b ? a : b);
}

class PairSection {
  /// `aspects`, `points` or `houses`.
  final String id;
  final List<PairReadingItem> items;
  const PairSection(this.id, this.items);
}

const _sectionOf = {
  FactorKind.synastry: 'aspects',
  FactorKind.synastryPoint: 'points',
  FactorKind.synastryHouse: 'houses',
};

/// Reading of a pair: each text once, heaviest first within a section.
List<PairSection> synastrySections(Synastry s, ContentRepository content) {
  final byKey = <String, List<Factor>>{};
  for (final f in synastryFactorsOf(s)) {
    byKey.putIfAbsent(f.key, () => []).add(f);
  }
  final out = <String, List<PairReadingItem>>{};
  for (final MapEntry(:key, :value) in byKey.entries) {
    out.putIfAbsent(_sectionOf[value.first.kind]!, () => []).add(PairReadingItem(key, content[key], value));
  }
  for (final l in out.values) {
    l.sort((a, b) => b.weight.compareTo(a.weight));
  }
  return [for (final id in ['aspects', 'points', 'houses']) if (out[id] != null) PairSection(id, out[id]!)];
}
