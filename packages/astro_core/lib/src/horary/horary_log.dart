import '../journal/log.dart';
import '../location.dart';
import '../version.dart' as v;

/// Outcome the user reports later ("jak to dopadlo?").
enum HoraryOutcome { yes, no, other }

/// One record of the question log (plan 10.8): either a question with the
/// verdict it got, or a later outcome of that question. Records are never
/// rewritten; a newer outcome supersedes an older one, both stay.
class HoraryRecord implements LogRecord {
  @override
  final String id;
  @override
  final DateTime createdAt;

  /// Id of the question this record belongs to (its own id for a question).
  final String question;

  /// Null for a question record.
  final HoraryOutcome? outcome;

  // Question fields (null on outcome records).
  /// The user's own words. Never read by the app; stored only in the
  /// encrypted log and printed only on explicit choice.
  final String? text;
  final String? topic;
  final String? person;
  final double? jdUt;
  final GeoLocation? place;

  /// Verdict id (`horary/verdict/{id}`), null for topics without a verdict.
  final String? verdict;
  final String engineVersion;

  HoraryRecord._({
    required this.id,
    required this.createdAt,
    required this.question,
    this.outcome,
    this.text,
    this.topic,
    this.person,
    this.jdUt,
    this.place,
    this.verdict,
    this.engineVersion = v.engineVersion,
  });

  factory HoraryRecord.question({
    required String id,
    required DateTime createdAt,
    required String text,
    required String topic,
    String person = 'self',
    required double jdUt,
    required GeoLocation place,
    required String? verdict,
  }) =>
      HoraryRecord._(id: id, createdAt: createdAt, question: id, text: text, topic: topic, person: person, jdUt: jdUt, place: place, verdict: verdict);

  factory HoraryRecord.outcomeOf(String question, {required String id, required DateTime createdAt, required HoraryOutcome outcome}) =>
      HoraryRecord._(id: id, createdAt: createdAt, question: question, outcome: outcome);

  bool get isQuestion => outcome == null;

  @override
  String get subject => isQuestion ? 'q:$question' : 'o:$question';
  @override
  String? get corrects => null;

  Map<String, Object?> toJson() => {
        'id': id,
        'created': createdAt.toUtc().toIso8601String(),
        'question': question,
        if (outcome != null) 'outcome': outcome!.name,
        if (text != null) 'text': text,
        if (topic != null) 'topic': topic,
        if (person != null) 'person': person,
        if (jdUt != null) 'jd': jdUt,
        if (place != null) 'place': place!.toJson(),
        if (verdict != null) 'verdict': verdict,
        'engine': engineVersion,
      };

  factory HoraryRecord.fromJson(Map<String, Object?> j) => HoraryRecord._(
        id: j['id'] as String,
        createdAt: DateTime.parse(j['created'] as String),
        question: j['question'] as String,
        outcome: j['outcome'] == null ? null : HoraryOutcome.values.byName(j['outcome'] as String),
        text: j['text'] as String?,
        topic: j['topic'] as String?,
        person: j['person'] as String?,
        jdUt: (j['jd'] as num?)?.toDouble(),
        place: j['place'] == null ? null : GeoLocation.fromJson((j['place'] as Map).cast<String, Object?>()),
        verdict: j['verdict'] as String?,
        engineVersion: j['engine'] as String? ?? '',
      );
}

/// A question is asked once; its outcome stays open for later answers.
class HoraryClosePolicy implements ClosePolicy {
  const HoraryClosePolicy();
  @override
  bool isOpen(String subject, DateTime now) => true;
}

/// Hit rate of the verdicts against the outcomes, with two baselines.
class HoraryHitRate {
  /// Closed yes/no questions (verdict for or against, outcome yes or no).
  final int n;
  final int hits;

  /// Hits of "always yes" and "always no" on the same questions.
  final int alwaysYes;
  final int alwaysNo;
  const HoraryHitRate(this.n, this.hits, this.alwaysYes, this.alwaysNo);

  double get rate => n == 0 ? 0 : hits / n;
  double get yesRate => n == 0 ? 0 : alwaysYes / n;
  double get noRate => n == 0 ? 0 : alwaysNo / n;
}

class HoraryLogSchemaError implements Exception {
  final int version;
  const HoraryLogSchemaError(this.version);
  @override
  String toString() => 'Horary log schema $version is newer than ${HoraryLog.schema}';
}

/// The question log of one profile (plan 10.8).
class HoraryLog {
  static const schema = 1;

  /// Hit rate is shown from this many closed yes/no questions.
  static const minForHitRate = 30;

  /// Same topic again within this time: tradition does not take a second try.
  static const repeatWindow = Duration(hours: 24);

  /// Ask "how did it turn out?" this long after the question.
  static const followUpAfter = Duration(days: 7);

  static const yesVerdicts = {'yes', 'yes_difficult'};
  static const noVerdicts = {'no', 'past', 'nothing'};

  final AppendOnlyLog<HoraryRecord> log;
  HoraryLog([Iterable<HoraryRecord> records = const []]) : log = AppendOnlyLog(records, const HoraryClosePolicy());

  List<HoraryRecord> get records => log.records;

  /// Questions, newest first.
  List<HoraryRecord> get questions => [for (final r in log.records.reversed) if (r.isQuestion) r];

  HoraryRecord? questionById(String id) => log.current('q:$id');

  /// The latest outcome of question [id].
  HoraryOutcome? outcomeOf(String id) => log.current('o:$id')?.outcome;

  HoraryLog append(HoraryRecord r, DateTime now) {
    if (!r.isQuestion && questionById(r.question) == null) throw LogRuleError('outcome of unknown question ${r.question}');
    if (r.isQuestion && questionById(r.question) != null) throw LogRuleError('question ${r.question} already asked');
    return HoraryLog(log.append(r, now).records);
  }

  /// The first question on the same topic and person in the last 24 hours.
  HoraryRecord? repeatOf(String topic, String person, DateTime now) {
    final hits = [
      for (final q in questions)
        if (q.topic == topic && q.person == person && now.difference(q.createdAt) < repeatWindow && !now.isBefore(q.createdAt)) q,
    ];
    return hits.lastOrNull;
  }

  /// Questions old enough for "how did it turn out?" and still without an outcome.
  List<HoraryRecord> dueFollowUps(DateTime now) => [
        for (final q in questions)
          if (q.verdict != null && outcomeOf(q.id) == null && now.difference(q.createdAt) >= followUpAfter) q,
      ];

  /// Verdict hits on closed yes/no questions; null below [minForHitRate].
  HoraryHitRate? hitRate() {
    var n = 0, hits = 0, yes = 0, no = 0;
    for (final q in questions) {
      final o = outcomeOf(q.id);
      final v = q.verdict;
      if (o == null || o == HoraryOutcome.other || v == null) continue;
      final saidYes = yesVerdicts.contains(v), saidNo = noVerdicts.contains(v);
      if (!saidYes && !saidNo) continue;
      n++;
      if ((saidYes && o == HoraryOutcome.yes) || (saidNo && o == HoraryOutcome.no)) hits++;
      if (o == HoraryOutcome.yes) yes++;
      if (o == HoraryOutcome.no) no++;
    }
    return n < minForHitRate ? null : HoraryHitRate(n, hits, yes, no);
  }

  Map<String, Object?> toJson() => {'schema': schema, 'records': [for (final r in log.records) r.toJson()]};

  factory HoraryLog.fromJson(Map<String, Object?> j) {
    final s = (j['schema'] as num?)?.toInt() ?? 1;
    if (s > schema) throw HoraryLogSchemaError(s);
    return HoraryLog([for (final r in (j['records'] as List? ?? const [])) HoraryRecord.fromJson((r as Map).cast<String, Object?>())]);
  }
}
