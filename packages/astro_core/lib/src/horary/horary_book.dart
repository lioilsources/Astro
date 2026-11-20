import '../model.dart';
import '../rules.dart';

/// A question topic of the closed list (plan 10.8): the house of the matter
/// and its natural significator, both from `content/rules/horary.json`.
class HoraryTopic {
  final String id;
  final int house;

  /// Natural significator (Lilly), null when the source names none.
  final Body? natural;

  /// Health, death, pregnancy: no verdict (owner decision 20).
  final bool noVerdict;

  /// Lost object: direction and kind of place are added.
  final bool lost;
  const HoraryTopic(this.id, this.house, {this.natural, this.noVerdict = false, this.lost = false});

  factory HoraryTopic.fromJson(Map<String, Object?> j) => HoraryTopic(
        j['id'] as String,
        (j['house'] as num).toInt(),
        natural: j['natural'] == null ? null : Body.values.byName(j['natural'] as String),
        noVerdict: j['noVerdict'] as bool? ?? false,
        lost: j['lost'] as bool? ?? false,
      );
}

/// Whom the question is about: the house of that person; the topic house is
/// then counted from it (derived houses, plan 10.8).
class HoraryPerson {
  final String id;
  final int house;
  const HoraryPerson(this.id, this.house);

  static const self = HoraryPerson('self', 1);
  bool get isSelf => house == 1;

  factory HoraryPerson.fromJson(Map<String, Object?> j) => HoraryPerson(j['id'] as String, (j['house'] as num).toInt());
}

/// House [topicHouse] counted from house [personHouse]: the brother's work is
/// the 10th from the 3rd, i.e. the 12th.
int derivedHouse(int personHouse, int topicHouse) => (personHouse - 1 + topicHouse - 1) % 12 + 1;

/// Kinds of house for timing: angular 1 4 7 10, succedent 2 5 8 11, cadent 3 6 9 12.
enum HouseKind {
  angular,
  succedent,
  cadent;

  static HouseKind of(int house) => HouseKind.values[(house - 1) % 3];
}

/// Parsed `content/rules/horary.json`.
class HoraryBook {
  final int version;
  final List<HoraryTopic> topics;
  final List<HoraryPerson> persons;

  /// Considerations before judgement: warnings, never blocking.
  final List<Rule> considerations;

  /// Testimonies for (plus) and against (minus) the matter.
  final List<Rule> testimonies;

  /// Time unit by the house kinds of the two significators, key
  /// `angular+succedent` (kinds in enum order), CA pp. 171–172.
  final Map<String, String> timing;

  /// Quarter of heaven by sign name and by house number (as string).
  final Map<String, String> lostBySign;
  final Map<String, String> lostByHouse;

  /// Free parameters of the decision tree (orb use, reception kinds).
  final Map<String, Object?> settings;

  const HoraryBook({
    required this.version,
    required this.topics,
    required this.persons,
    required this.considerations,
    required this.testimonies,
    required this.timing,
    required this.lostBySign,
    required this.lostByHouse,
    this.settings = const {},
  });

  factory HoraryBook.fromJson(Map<String, Object?> j) {
    List<Map<String, Object?>> list(String k) => [for (final e in (j[k] as List? ?? const [])) (e as Map).cast<String, Object?>()];
    final timing = (j['timing'] as Map).cast<String, Object?>();
    final lost = (j['lost'] as Map).cast<String, Object?>();
    Map<String, String> strMap(Object? m) => {for (final e in (m as Map).entries) e.key as String: e.value as String};
    return HoraryBook(
      version: (j['version'] as num?)?.toInt() ?? 1,
      topics: [for (final t in list('topics')) HoraryTopic.fromJson(t)],
      persons: [for (final p in list('persons')) HoraryPerson.fromJson(p)],
      considerations: [for (final r in list('considerations')) Rule.fromJson(r)],
      testimonies: [for (final r in list('testimonies')) Rule.fromJson(r)],
      timing: strMap(timing['units']),
      lostBySign: strMap(lost['signs']),
      lostByHouse: strMap(lost['houses']),
      settings: (j['settings'] as Map?)?.cast<String, Object?>() ?? const {},
    );
  }

  HoraryTopic topic(String id) => topics.firstWhere((t) => t.id == id, orElse: () => throw ArgumentError('unknown topic $id'));
  HoraryPerson person(String id) => persons.firstWhere((p) => p.id == id, orElse: () => throw ArgumentError('unknown person $id'));

  bool setting(String k, bool d) => settings[k] as bool? ?? d;

  /// Unit for significators in houses of kinds [a] and [b].
  String timeUnit(HouseKind a, HouseKind b) => timing[timingKey(a, b)] ?? 'unknown';

  static String timingKey(HouseKind a, HouseKind b) => a.index <= b.index ? '${a.name}+${b.name}' : '${b.name}+${a.name}';
}
