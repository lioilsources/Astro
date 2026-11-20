/// Rules as data (plan 10.7, reused by horary in 10.8): a rule file lists
/// rules with a kind, a weight, the intents they apply to and the key of their
/// text; code only supplies one predicate per condition (`when`) and evaluates.
library;

enum RuleKind { exclude, plus, minus }

/// Whether a rule needs a natal chart (personal layer) or only the sky.
enum RuleLayer { sky, personal }

class Rule {
  final String id;
  final RuleKind kind;

  /// Points added (plus) or taken (minus); 0 for exclude rules.
  final int weight;

  /// Intent ids the rule applies to; empty = all intents.
  final List<String> intents;
  final RuleLayer layer;

  /// Content key of the explanation, e.g. `election/rule/moon_waxing`.
  final String textKey;

  /// Name of the condition the code evaluates (several rules may share one
  /// condition with different [params]).
  final String when;
  final Map<String, Object?> params;

  const Rule({
    required this.id,
    required this.kind,
    required this.weight,
    this.intents = const [],
    this.layer = RuleLayer.sky,
    required this.textKey,
    required this.when,
    this.params = const {},
  });

  bool appliesTo(String? intent) => intents.isEmpty || intent == null || intents.contains(intent);

  /// Signed contribution to the score.
  int get points => switch (kind) {
        RuleKind.plus => weight,
        RuleKind.minus => -weight,
        RuleKind.exclude => 0,
      };

  factory Rule.fromJson(Map<String, Object?> j) => Rule(
        id: j['id'] as String,
        kind: RuleKind.values.byName(j['kind'] as String),
        weight: (j['weight'] as num).toInt(),
        intents: (j['intents'] as List? ?? const []).cast<String>(),
        layer: RuleLayer.values.byName(j['layer'] as String? ?? 'sky'),
        textKey: j['text'] as String,
        when: j['when'] as String,
        params: (j['params'] as Map?)?.cast<String, Object?>() ?? const {},
      );

  // Typed parameter access with defaults.
  double number(String k, double d) => (params[k] as num?)?.toDouble() ?? d;
  List<String> strings(String k) => (params[k] as List? ?? const []).cast<String>();
  List<int> ints(String k) => [for (final v in (params[k] as List? ?? const [])) (v as num).toInt()];

  @override
  String toString() => '$id(${kind.name} $weight)';
}

/// A parsed rule file: the rules plus named score thresholds.
class RuleBook {
  final int version;
  final List<Rule> rules;

  /// Verdict thresholds, e.g. {strong: 8, good: 4, weak: 1}: minimum score.
  final Map<String, int> thresholds;
  const RuleBook(this.version, this.rules, this.thresholds);

  factory RuleBook.fromJson(Map<String, Object?> j) => RuleBook(
        (j['version'] as num?)?.toInt() ?? 1,
        [for (final r in (j['rules'] as List).cast<Map>()) Rule.fromJson(r.cast<String, Object?>())],
        {for (final e in ((j['thresholds'] as Map?) ?? const {}).entries) e.key as String: (e.value as num).toInt()},
      );

  Rule? operator [](String id) => rules.where((r) => r.id == id).firstOrNull;

  /// Rules that apply to [intent], without personal ones when [personal] is false.
  List<Rule> active(String? intent, {required bool personal}) =>
      [for (final r in rules) if (r.appliesTo(intent) && (personal || r.layer == RuleLayer.sky)) r];

  /// Name of the highest threshold [score] reaches, or null below all of them.
  String? verdictOf(int score) {
    final sorted = thresholds.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return sorted.where((e) => score >= e.value).firstOrNull?.key;
  }
}

/// Condition of a rule over a context [C] (one moment of the sky, a horary chart…).
typedef RulePredicate<C> = bool Function(C ctx, Rule rule);

/// Rules that fired for one context.
class RuleOutcome {
  /// Fired rules in rule-file order.
  final List<Rule> fired;
  const RuleOutcome(this.fired);

  bool get excluded => fired.any((r) => r.kind == RuleKind.exclude);
  int get score => fired.fold(0, (s, r) => s + r.points);
  List<Rule> get plus => [for (final r in fired) if (r.kind == RuleKind.plus) r];
  List<Rule> get minus => [for (final r in fired) if (r.kind == RuleKind.minus) r];

  /// Identity of the outcome: equal signatures = equal results (used to merge samples).
  String get signature => fired.map((r) => r.id).join(',');
}

/// Evaluates [rules] on [ctx]. Every rule's `when` must have a predicate.
RuleOutcome evaluateRules<C>(List<Rule> rules, Map<String, RulePredicate<C>> predicates, C ctx) {
  final fired = <Rule>[];
  for (final r in rules) {
    final p = predicates[r.when];
    if (p == null) throw ArgumentError('no predicate for condition ${r.when} (rule ${r.id})');
    if (p(ctx, r)) fired.add(r);
  }
  return RuleOutcome(fired);
}
