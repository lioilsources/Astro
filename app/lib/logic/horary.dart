import 'dart:convert';
import 'dart:io';

import 'package:astro_core/astro_core.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/journal_store.dart';
import '../platform/background.dart';

/// Horary rules bundled from `content/rules/horary.json` (plan 10.8).
final horaryBookProvider = FutureProvider<HoraryBook>((ref) async =>
    HoraryBook.fromJson((jsonDecode(await rootBundle.loadString('assets/rules/horary.json')) as Map).cast<String, Object?>()));

/// Judges a question off the UI thread.
Future<HoraryJudgement> judgeHorary(HoraryQuestion q, HoraryBook book) => background(() => HoraryEngine.judge(q, book));

/// The question to recompute a judgement from a logged question.
HoraryQuestion questionOf(HoraryRecord r) => HoraryQuestion(jdUt: r.jdUt!, place: r.place!, topic: r.topic!, person: r.person ?? 'self');

/// Question logs, one encrypted file per profile (plan 10.8). The question text
/// lives only here, encrypted; nothing leaves the device.
class HoraryStore {
  final EncryptedJsonFiles files;
  HoraryStore({KeyVault? vault, Future<Directory> Function()? dir})
      : files = EncryptedJsonFiles('astro_horary_key_v1', vault: vault, dir: dir);

  static String pathOf(String profileId) => 'horary/${base64Url.encode(utf8.encode(profileId)).replaceAll('=', '')}.bin';

  /// Throws [HoraryLogSchemaError] for a file written by a newer app.
  Future<HoraryLog> load(String profileId) async {
    final json = await files.read(pathOf(profileId));
    if (json == null) return HoraryLog();
    return HoraryLog.fromJson((json as Map).cast<String, Object?>());
  }

  Future<void> save(String profileId, HoraryLog log) => files.write(pathOf(profileId), log.toJson());

  Future<void> delete(String profileId) => files.delete(pathOf(profileId));
}

final horaryStoreProvider = Provider<HoraryStore>((ref) => HoraryStore());

class HoraryLogNotifier extends AsyncNotifier<HoraryLog> {
  HoraryLogNotifier(this.profileId);
  final String profileId;

  /// Injectable clock for tests.
  static DateTime Function() clock = DateTime.now;

  @override
  Future<HoraryLog> build() => ref.read(horaryStoreProvider).load(profileId);

  Future<void> _set(HoraryLog log) async {
    state = AsyncData(log);
    await ref.read(horaryStoreProvider).save(profileId, log);
  }

  /// Logs a judged question and returns its record.
  Future<HoraryRecord> addQuestion(String text, HoraryJudgement j) async {
    final log = await future;
    final now = clock();
    final q = j.question;
    final r = HoraryRecord.question(
      id: '${now.microsecondsSinceEpoch}',
      createdAt: now.toUtc(),
      text: text.trim(),
      topic: q.topic,
      person: q.person,
      jdUt: q.jdUt,
      place: q.place,
      verdict: j.verdict?.id,
    );
    await _set(log.append(r, now));
    return r;
  }

  Future<void> setOutcome(String questionId, HoraryOutcome o) async {
    final log = await future;
    final now = clock();
    await _set(log.append(HoraryRecord.outcomeOf(questionId, id: 'o${now.microsecondsSinceEpoch}', createdAt: now.toUtc(), outcome: o), now));
  }
}

final horaryLogProvider = AsyncNotifierProvider.family<HoraryLogNotifier, HoraryLog, String>(HoraryLogNotifier.new);
