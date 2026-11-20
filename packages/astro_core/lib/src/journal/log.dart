/// Generic append-only log (plan 10.3, reused by the horary question log, R8).
///
/// Records are never rewritten. While a subject (a day, a question) is open,
/// a newer record for it supersedes the older one, but both stay in the log.
/// Once the subject closes, the only way to change it is a correction: a new
/// record that points to the closed original via [LogRecord.corrects].
library;

/// One record of an [AppendOnlyLog].
abstract interface class LogRecord {
  String get id;

  /// What the record is about: a day key, a question id, …
  String get subject;

  /// When the record was appended (UTC).
  DateTime get createdAt;

  /// Id of the closed original this record corrects; null for an original.
  String? get corrects;
}

/// Decides when a subject accepts originals.
abstract interface class ClosePolicy {
  /// True when an original record for [subject] may be appended at [now].
  bool isOpen(String subject, DateTime now);
}

class LogRuleError implements Exception {
  final String message;
  const LogRuleError(this.message);
  @override
  String toString() => 'LogRuleError: $message';
}

class AppendOnlyLog<R extends LogRecord> {
  final List<R> records;
  final ClosePolicy policy;

  /// [records] in append order. Loaded logs are trusted: the rules were checked on append.
  AppendOnlyLog(Iterable<R> records, this.policy) : records = List.unmodifiable(records);

  /// Returns a new log with [r] appended, or throws [LogRuleError].
  AppendOnlyLog<R> append(R r, DateTime now) {
    if (records.any((x) => x.id == r.id)) throw LogRuleError('duplicate id ${r.id}');
    final open = policy.isOpen(r.subject, now);
    if (r.corrects == null) {
      if (!open) throw LogRuleError('${r.subject} is closed; append a correction instead');
    } else {
      final target = records.where((x) => x.id == r.corrects).firstOrNull;
      if (target == null) throw LogRuleError('correction of unknown record ${r.corrects}');
      if (target.subject != r.subject) throw LogRuleError('correction must keep the subject');
      if (target.corrects != null) throw LogRuleError('correct the original, not a correction');
      if (original(r.subject)?.id != target.id) throw LogRuleError('only the final original can be corrected');
      if (open) throw LogRuleError('${r.subject} is still open; append a new original instead');
    }
    return AppendOnlyLog([...records, r], policy);
  }

  /// Subjects in order of their first record.
  List<String> get subjects => {for (final r in records) r.subject}.toList();

  /// All records of [subject] in append order.
  List<R> history(String subject) => [for (final r in records) if (r.subject == subject) r];

  /// The original that counts: the last non-correction record (appended while open).
  R? original(String subject) => history(subject).where((r) => r.corrects == null).lastOrNull;

  /// Corrections appended after the subject closed.
  List<R> corrections(String subject) => [for (final r in history(subject)) if (r.corrects != null) r];

  /// What to show: the latest correction, or the original.
  R? current(String subject) => history(subject).lastOrNull;

  bool isOpen(String subject, DateTime now) => policy.isOpen(subject, now);
}

/// Civil date as a day number (days since 1970-01-01), free of time zones and DST.
int dayNumber(int year, int month, int day) => DateTime.utc(year, month, day).millisecondsSinceEpoch ~/ 86400000;

/// Day number of the local calendar date of [t].
int dayNumberOf(DateTime t) => dayNumber(t.year, t.month, t.day);

DateTime dateOfDayNumber(int n) => DateTime.utc(1970).add(Duration(days: n));

String _two(int v) => v.toString().padLeft(2, '0');

/// `yyyy-mm-dd` of a day number.
String dayKeyOf(int n) {
  final d = dateOfDayNumber(n);
  return '${d.year.toString().padLeft(4, '0')}-${_two(d.month)}-${_two(d.day)}';
}

int parseDayKey(String key) {
  final p = key.split('-').map(int.parse).toList();
  return dayNumber(p[0], p[1], p[2]);
}

/// Day subjects (`yyyy-mm-dd`): open from the start of the day until the end of
/// the following day, local time. Future days are not open yet.
class DayClosePolicy implements ClosePolicy {
  /// Days after the subject day that still accept originals (plan: the following day).
  final int graceDays;
  const DayClosePolicy({this.graceDays = 1});

  @override
  bool isOpen(String subject, DateTime now) {
    final day = parseDayKey(subject), today = dayNumberOf(now);
    return today >= day && today <= day + graceDays;
  }
}
