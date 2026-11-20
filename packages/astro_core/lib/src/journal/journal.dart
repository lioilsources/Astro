import '../aspects.dart';
import '../model.dart';
import '../version.dart' as v;
import 'log.dart';

const minRating = -2, maxRating = 2;

/// Rating of one day (plan 10.3). Transits are not stored; they can be recomputed.
class DayRating implements LogRecord {
  @override
  final String id;

  /// `yyyy-mm-dd`, local calendar date.
  final String day;
  @override
  final DateTime createdAt;

  /// −2 … +2.
  final int rating;

  /// Trait ids from the vocabulary (content/cs/traits.json).
  final List<String> tags;
  final String note;

  /// Julian Day UT of local noon of [day]; the moment the tension was computed for.
  final double jd;

  /// Daily tension score at [jd] (`TransitEngine.tensionAt`).
  final double tension;
  final String engineVersion;
  final int formulaVersion;

  /// The user could see the forecast before rating (always outside the blind test).
  final bool sawPrediction;
  @override
  final String? corrects;

  DayRating({
    required this.id,
    required this.day,
    required this.createdAt,
    required this.rating,
    this.tags = const [],
    this.note = '',
    required this.jd,
    required this.tension,
    this.engineVersion = v.engineVersion,
    this.formulaVersion = v.tensionFormulaVersion,
    this.sawPrediction = true,
    this.corrects,
  }) {
    if (rating < minRating || rating > maxRating) throw RangeError.range(rating, minRating, maxRating, 'rating');
  }

  @override
  String get subject => day;
  int get dayNumber => parseDayKey(day);

  Map<String, Object?> toJson() => {
        'id': id,
        'day': day,
        'created': createdAt.toUtc().toIso8601String(),
        'rating': rating,
        if (tags.isNotEmpty) 'tags': tags,
        if (note.isNotEmpty) 'note': note,
        'jd': jd,
        'tension': tension,
        'engine': engineVersion,
        'formula': formulaVersion,
        'saw': sawPrediction,
        if (corrects != null) 'corrects': corrects,
      };

  factory DayRating.fromJson(Map<String, Object?> j) => DayRating(
        id: j['id'] as String,
        day: j['day'] as String,
        createdAt: DateTime.parse(j['created'] as String),
        rating: j['rating'] as int,
        tags: (j['tags'] as List? ?? const []).cast<String>(),
        note: j['note'] as String? ?? '',
        jd: (j['jd'] as num).toDouble(),
        tension: (j['tension'] as num).toDouble(),
        // Fields added later default to "unknown", which forces a recompute.
        engineVersion: j['engine'] as String? ?? 'unknown',
        formulaVersion: j['formula'] as int? ?? 0,
        sawPrediction: j['saw'] as bool? ?? true,
        corrects: j['corrects'] as String?,
      );
}

/// A rule written down in advance: "when [transiting] makes [type] to [target], I get [tag]".
/// Only days after [createdDay] count.
class Hypothesis {
  final String id;
  final String createdDay;
  final Body transiting;
  final AspectType type;
  final ChartPoint target;
  final String tag;

  const Hypothesis({
    required this.id,
    required this.createdDay,
    required this.transiting,
    required this.type,
    required this.target,
    required this.tag,
  });

  Map<String, Object?> toJson() => {
        'id': id,
        'created': createdDay,
        'transiting': transiting.name,
        'type': type.name,
        'target': target.id,
        'tag': tag,
      };

  factory Hypothesis.fromJson(Map<String, Object?> j) {
    final t = j['target'] as String;
    return Hypothesis(
      id: j['id'] as String,
      createdDay: j['created'] as String,
      transiting: Body.values.byName(j['transiting'] as String),
      type: AspectType.values.byName(j['type'] as String),
      target: Angle.values.any((a) => a.name == t) ? ChartPoint.angle(Angle.values.byName(t)) : ChartPoint.body(Body.values.byName(t)),
      tag: j['tag'] as String,
    );
  }
}

/// The voluntary blind test (plan 10.3, owner decision 16: off by default).
class BlindTest {
  static const lengthDays = 90;
  final String startDay;

  /// Set when the user stops the test early.
  final String? stoppedDay;
  const BlindTest(this.startDay, {this.stoppedDay});

  int get _start => parseDayKey(startDay);
  int get lastDay => stoppedDay == null ? _start + lengthDays - 1 : parseDayKey(stoppedDay!) - 1;

  bool activeOn(int dayNumber) => dayNumber >= _start && dayNumber <= lastDay;

  Map<String, Object?> toJson() => {'start': startDay, if (stoppedDay != null) 'stopped': stoppedDay};
  factory BlindTest.fromJson(Map<String, Object?> j) => BlindTest(j['start'] as String, stoppedDay: j['stopped'] as String?);
}

class JournalSchemaError implements Exception {
  final int found;
  const JournalSchemaError(this.found);
  @override
  String toString() => 'Journal schema $found is newer than this app ($journalSchema)';
}

/// Version of the stored journal document.
const journalSchema = 1;

/// The prediction journal of one profile.
class Journal {
  final AppendOnlyLog<DayRating> log;
  final List<Hypothesis> hypotheses;
  final List<BlindTest> blindTests;

  Journal({Iterable<DayRating> ratings = const [], this.hypotheses = const [], this.blindTests = const []})
      : log = AppendOnlyLog(ratings, const DayClosePolicy());

  Journal._(this.log, this.hypotheses, this.blindTests);

  Journal copyWith({AppendOnlyLog<DayRating>? log, List<Hypothesis>? hypotheses, List<BlindTest>? blindTests}) =>
      Journal._(log ?? this.log, hypotheses ?? this.hypotheses, blindTests ?? this.blindTests);

  List<DayRating> get ratings => log.records;

  /// Appends a rating or a correction (throws [LogRuleError]).
  Journal append(DayRating r, DateTime now) => copyWith(log: log.append(r, now));

  BlindTest? blindOn(int dayNumber) => blindTests.where((b) => b.activeOn(dayNumber)).firstOrNull;

  /// Whether a rating of [day] appended at [now] is blind: the blind test runs and
  /// the transits view is still locked (today not rated yet, or rating today itself).
  bool isBlindRating(String day, DateTime now) {
    final today = dayNumberOf(now);
    if (blindOn(today) == null) return false;
    return parseDayKey(day) == today || log.original(dayKeyOf(today)) == null;
  }

  /// Transits view locked: blind test runs and today has no rating yet.
  bool transitsLocked(DateTime now) {
    final today = dayNumberOf(now);
    return blindOn(today) != null && log.original(dayKeyOf(today)) == null;
  }

  Journal startBlind(DateTime now) {
    if (blindOn(dayNumberOf(now)) != null) return this;
    return copyWith(blindTests: [...blindTests, BlindTest(dayKeyOf(dayNumberOf(now)))]);
  }

  Journal stopBlind(DateTime now) {
    final today = dayNumberOf(now);
    return copyWith(blindTests: [
      for (final b in blindTests) b.activeOn(today) ? BlindTest(b.startDay, stoppedDay: dayKeyOf(today)) : b,
    ]);
  }

  /// Originals in day order: the ratings that are evaluated (corrections are not,
  /// a later change of mind can be coloured by hindsight).
  List<DayRating> get evaluated {
    final out = [for (final s in log.subjects) log.original(s)].whereType<DayRating>().toList();
    return out..sort((a, b) => a.dayNumber.compareTo(b.dayNumber));
  }

  Map<String, Object?> toJson() => {
        'schema': journalSchema,
        'ratings': [for (final r in ratings) r.toJson()],
        'hypotheses': [for (final h in hypotheses) h.toJson()],
        'blind': [for (final b in blindTests) b.toJson()],
      };

  /// Decodes any stored schema up to [journalSchema]; refuses newer ones so an older
  /// app never overwrites data it does not understand.
  factory Journal.fromJson(Map<String, Object?> j) {
    final schema = j['schema'] as int? ?? 1;
    if (schema > journalSchema) throw JournalSchemaError(schema);
    List<Map<String, Object?>> list(String k) => [for (final e in (j[k] as List? ?? const [])) (e as Map).cast<String, Object?>()];
    return Journal(
      ratings: list('ratings').map(DayRating.fromJson),
      hypotheses: list('hypotheses').map(Hypothesis.fromJson).toList(),
      blindTests: list('blind').map(BlindTest.fromJson).toList(),
    );
  }
}

String _csvCell(String s) => RegExp(r'[",\n\r;]').hasMatch(s) ? '"${s.replaceAll('"', '""')}"' : s;

/// CSV export of the whole log, corrections included (plan 10.3).
String journalCsv(Journal j) {
  const header = ['id', 'day', 'created_utc', 'rating', 'tags', 'note', 'tension', 'engine_version', 'formula_version', 'saw_prediction', 'corrects'];
  final rows = [
    header.join(','),
    for (final r in j.ratings)
      [
        r.id,
        r.day,
        r.createdAt.toUtc().toIso8601String(),
        '${r.rating}',
        r.tags.join(' '),
        r.note,
        r.tension.toStringAsFixed(2),
        r.engineVersion,
        '${r.formulaVersion}',
        r.sawPrediction ? '1' : '0',
        r.corrects ?? '',
      ].map(_csvCell).join(','),
  ];
  return '${rows.join('\n')}\n';
}
