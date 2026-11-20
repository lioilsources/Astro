import 'package:astro_core/astro_core.dart';
import 'package:astro_core/journal.dart' show LogRuleError;
import 'package:test/test.dart';

const _place = GeoLocation(lat: 50.0833, lon: 14.4167, name: 'Praha', zone: 'Europe/Prague');

HoraryRecord _q(String id, DateTime at, {String topic = 'career', String person = 'self', String? verdict = 'yes'}) => HoraryRecord.question(
      id: id,
      createdAt: at,
      text: 'otázka $id',
      topic: topic,
      person: person,
      jdUt: jdFromDateTimeUtc(at),
      place: _place,
      verdict: verdict,
    );

void main() {
  final t0 = DateTime.utc(2026, 3, 1, 10);

  test('log is append-only: a question is asked once, outcomes supersede but stay', () {
    var log = HoraryLog().append(_q('a', t0), t0);
    expect(() => log.append(_q('a', t0), t0), throwsA(isA<LogRuleError>()));
    expect(
      () => log.append(HoraryRecord.outcomeOf('nope', id: 'o1', createdAt: t0, outcome: HoraryOutcome.yes), t0),
      throwsA(isA<LogRuleError>()),
    );
    log = log.append(HoraryRecord.outcomeOf('a', id: 'o1', createdAt: t0, outcome: HoraryOutcome.no), t0);
    log = log.append(HoraryRecord.outcomeOf('a', id: 'o2', createdAt: t0, outcome: HoraryOutcome.yes), t0);
    expect(log.outcomeOf('a'), HoraryOutcome.yes);
    expect(log.records.length, 3);
    final back = HoraryLog.fromJson(log.toJson());
    expect(back.records.map((r) => r.id), ['a', 'o1', 'o2']);
    expect(back.questionById('a')!.text, 'otázka a');
    expect(back.questionById('a')!.place, _place);
  });

  test('same topic and person within 24 h is a repeat; the first question is returned', () {
    var log = HoraryLog().append(_q('a', t0), t0);
    log = log.append(_q('b', t0.add(const Duration(hours: 2))), t0.add(const Duration(hours: 2)));
    expect(log.repeatOf('career', 'self', t0.add(const Duration(hours: 3)))!.id, 'a');
    expect(log.repeatOf('career', 'sibling', t0.add(const Duration(hours: 3))), isNull);
    expect(log.repeatOf('money', 'self', t0.add(const Duration(hours: 3))), isNull);
    expect(log.repeatOf('career', 'self', t0.add(const Duration(hours: 25)))!.id, 'b');
    expect(log.repeatOf('career', 'self', t0.add(const Duration(hours: 27))), isNull);
  });

  test('follow-up after a week, only for questions with a verdict and without outcome', () {
    var log = HoraryLog().append(_q('a', t0), t0).append(_q('h', t0, topic: 'health', verdict: null), t0);
    expect(log.dueFollowUps(t0.add(const Duration(days: 6))), isEmpty);
    expect(log.dueFollowUps(t0.add(const Duration(days: 8))).map((q) => q.id), ['a']);
    log = log.append(HoraryRecord.outcomeOf('a', id: 'o', createdAt: t0, outcome: HoraryOutcome.other), t0);
    expect(log.dueFollowUps(t0.add(const Duration(days: 8))), isEmpty);
  });

  test('hit rate from 30 closed yes/no questions, against always-yes and always-no', () {
    var log = HoraryLog();
    var at = t0;
    for (var i = 0; i < 40; i++) {
      at = at.add(const Duration(days: 2));
      // 20 "yes" verdicts, 20 "no"-family verdicts; outcomes: yes for i % 4 != 0.
      final verdict = i.isEven ? 'yes' : (i % 3 == 0 ? 'nothing' : 'no');
      log = log.append(_q('q$i', at, topic: 'topic$i', verdict: verdict), at);
      if (i < 29) {
        log = log.append(HoraryRecord.outcomeOf('q$i', id: 'o$i', createdAt: at, outcome: i % 4 != 0 ? HoraryOutcome.yes : HoraryOutcome.no), at);
      }
    }
    expect(log.hitRate(), isNull, reason: '29 closed questions');
    log = log.append(HoraryRecord.outcomeOf('q29', id: 'o29', createdAt: at, outcome: HoraryOutcome.yes), at);
    // An unclear verdict or an "other" outcome does not count.
    log = log.append(_q('u', at, topic: 'x', verdict: 'unclear'), at).append(HoraryRecord.outcomeOf('u', id: 'ou', createdAt: at, outcome: HoraryOutcome.yes), at);
    log = log.append(HoraryRecord.outcomeOf('q30', id: 'o30', createdAt: at, outcome: HoraryOutcome.other), at);
    final hr = log.hitRate()!;
    expect(hr.n, 30);
    var hits = 0, yes = 0;
    for (var i = 0; i < 30; i++) {
      final outYes = i == 29 || i % 4 != 0;
      if (outYes) yes++;
      if (i.isEven == outYes) hits++;
    }
    expect(hr.hits, hits);
    expect(hr.alwaysYes, yes);
    expect(hr.alwaysNo, 30 - yes);
  });

  test('newer schema is refused', () {
    expect(() => HoraryLog.fromJson({'schema': 99, 'records': []}), throwsA(isA<HoraryLogSchemaError>()));
  });
}
