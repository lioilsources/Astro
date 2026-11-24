import 'package:astro_core/astro_core.dart';
import 'package:astro_core/journal.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/journal_store.dart';
import 'data/reminder.dart';

final journalStoreProvider = Provider<JournalStore>((ref) => JournalStore());

/// Prediction journal of one profile, by profile id (plan 10.3).
class JournalNotifier extends AsyncNotifier<Journal> {
  JournalNotifier(this.profileId);
  final String profileId;

  /// Injectable clock for tests.
  static DateTime Function() clock = DateTime.now;

  @override
  Future<Journal> build() => ref.read(journalStoreProvider).load(profileId);

  Future<void> _set(Journal j) async {
    state = AsyncData(j);
    await ref.read(journalStoreProvider).save(profileId, j);
  }

  /// Rates [day] (or corrects the closed record [corrects]). Throws [LogRuleError].
  Future<void> rate(Chart chart, {required String day, required int rating, List<String> tags = const [], String note = '', String? corrects}) async {
    final j = await future;
    final now = clock();
    final d = dateOfDayNumber(parseDayKey(day));
    final jd = jdFromDateTimeUtc(DateTime(d.year, d.month, d.day, 12).toUtc());
    final r = DayRating(
      id: '${now.microsecondsSinceEpoch}',
      day: day,
      createdAt: now.toUtc(),
      rating: rating,
      tags: tags,
      note: note.trim(),
      jd: jd,
      tension: TransitEngine(chart).tensionAt(jd),
      sawPrediction: corrects != null || !j.isBlindRating(day, now),
      corrects: corrects,
    );
    await _set(j.append(r, now));
  }

  Future<void> addHypothesis(Hypothesis h) async {
    final j = await future;
    await _set(j.copyWith(hypotheses: [...j.hypotheses, h]));
  }

  Future<void> removeHypothesis(String id) async {
    final j = await future;
    await _set(j.copyWith(hypotheses: [for (final h in j.hypotheses) if (h.id != id) h]));
  }

  Future<void> setBlind(bool on) async {
    final j = await future;
    await _set(on ? j.startBlind(clock()) : j.stopBlind(clock()));
  }
}

final journalProvider = AsyncNotifierProvider.family<JournalNotifier, Journal, String>(JournalNotifier.new);

final remindersProvider = Provider<Reminders>((ref) => kIsWeb ? NoReminders() : LocalReminders());

class ReminderNotifier extends AsyncNotifier<ReminderSettings> {
  @override
  Future<ReminderSettings> build() => ReminderSettings.load();

  /// Returns false when the notification permission was denied (the setting stays off).
  Future<bool> change(ReminderSettings next, {required String title, required String body}) async {
    var s = next;
    if (s.enabled) {
      final ok = await ref.read(remindersProvider).schedule(s.minutes, title: title, body: body);
      if (!ok) s = s.copyWith(enabled: false);
    } else {
      await ref.read(remindersProvider).cancel();
    }
    state = AsyncData(s);
    await s.save();
    return s.enabled == next.enabled;
  }
}

final reminderProvider = AsyncNotifierProvider<ReminderNotifier, ReminderSettings>(ReminderNotifier.new);
