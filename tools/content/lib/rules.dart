import 'dart:convert';
import 'dart:io';

import 'package:astro_core/astro_core.dart'
    show Body, ElectionIntent, HoraryBook, HouseKind, RuleKind, RuleLayer, Sign, electionConditions, electionVerdictIds, horaryConditions;

import 'schema.dart';
import 'validate.dart';

/// `content/rules/election.json` as raw JSON.
Map<String, Object?> loadElectionRules(Directory contentRoot) =>
    (jsonDecode(File('${contentRoot.path}/rules/election.json').readAsStringSync()) as Map).cast<String, Object?>();

/// Schema of the election rule file (plan 10.7): every rule has an id, a kind,
/// a weight, known intents, a known condition, a text key and a description.
List<Finding> validateElectionRules(Map<String, Object?> json) {
  final out = <Finding>[];
  void err(String key, String m) => out.add(Finding(key, m, error: true));
  const file = 'rules/election';
  if (json['version'] is! int) err(file, 'version must be an integer');
  final thresholds = json['thresholds'];
  if (thresholds is! Map || thresholds.isEmpty) {
    err(file, 'thresholds missing');
  } else {
    for (final MapEntry(:key, :value) in thresholds.entries) {
      if (!electionVerdictIds.contains(key)) err(file, 'threshold $key is not a verdict id');
      if (value is! int) err(file, 'threshold $key must be an integer');
    }
  }
  final rules = json['rules'];
  if (rules is! List || rules.isEmpty) {
    err(file, 'rules missing');
    return out;
  }
  final ids = <String>{};
  final intents = {for (final i in ElectionIntent.values) i.id};
  final keys = allKeysByFamily()['election']!.toSet();
  for (final raw in rules) {
    if (raw is! Map) {
      err(file, 'rule is not an object');
      continue;
    }
    final id = raw['id'];
    final k = 'rule/$id';
    if (id is! String || !RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(id)) {
      err(file, 'bad rule id $id');
      continue;
    }
    if (!ids.add(id)) err(k, 'duplicate id');
    final kind = RuleKind.values.where((x) => x.name == raw['kind']).firstOrNull;
    if (kind == null) err(k, 'kind must be one of ${RuleKind.values.map((x) => x.name).join(', ')}');
    final w = raw['weight'];
    if (w is! int) {
      err(k, 'weight missing');
    } else if (kind == RuleKind.exclude && w != 0) {
      err(k, 'exclude rules have weight 0');
    } else if (kind != RuleKind.exclude && w <= 0) {
      err(k, 'weight must be positive');
    }
    final layer = raw['layer'] ?? 'sky';
    if (!RuleLayer.values.any((x) => x.name == layer)) err(k, 'unknown layer $layer');
    for (final i in (raw['intents'] as List? ?? const [])) {
      if (!intents.contains(i)) err(k, 'unknown intent $i');
    }
    if (!electionConditions.contains(raw['when'])) err(k, 'unknown condition ${raw['when']}');
    if (raw['text'] != 'election/rule/$id') err(k, 'text must be election/rule/$id');
    if (!keys.contains('election/rule/$id')) err(k, 'no content key election/rule/$id (keys.dart electionRuleIds)');
    if ((raw['about'] as String? ?? '').trim().isEmpty) err(k, 'empty about');
    if (raw['params'] != null && raw['params'] is! Map) err(k, 'params must be an object');
  }
  for (final r in electionRuleIds) {
    if (!ids.contains(r)) err('rule/$r', 'listed in keys.dart but missing in the rule file');
  }
  return out;
}

/// `content/rules/horary.json` as raw JSON.
Map<String, Object?> loadHoraryRules(Directory contentRoot) =>
    (jsonDecode(File('${contentRoot.path}/rules/horary.json').readAsStringSync()) as Map).cast<String, Object?>();

/// Schema of the horary rule file (plan 10.8): topics with a house, persons,
/// considerations and testimonies with a known condition, a text key, a
/// description and a source; complete timing and lost-object tables.
List<Finding> validateHoraryRules(Map<String, Object?> json) {
  final out = <Finding>[];
  void err(String key, String m) => out.add(Finding(key, m, error: true));
  const file = 'rules/horary';
  if (json['version'] is! int) err(file, 'version must be an integer');
  final keys = allKeysByFamily()['horary']!.toSet();
  final bodies = {for (final b in Body.traditional) b.name};

  final topics = json['topics'];
  if (topics is! List || topics.isEmpty) {
    err(file, 'topics missing');
  } else {
    final ids = <String>{};
    for (final t in topics.cast<Map>()) {
      final id = t['id'];
      if (id is! String || !ids.add(id)) err(file, 'bad or duplicate topic id $id');
      final h = t['house'];
      if (h is! int || h < 1 || h > 12) err('topic/$id', 'house must be 1–12');
      final n = t['natural'];
      if (n != null && !bodies.contains(n)) err('topic/$id', 'natural must be one of the seven planets');
      if ((t['source'] as String? ?? '').trim().isEmpty) err('topic/$id', 'empty source');
    }
  }
  final persons = json['persons'];
  if (persons is! List || persons.cast<Map>().where((p) => p['id'] == 'self' && p['house'] == 1).isEmpty) {
    err(file, 'persons must include self in house 1');
  }

  void rules(String section, String prefix, List<String> expected, {required bool testimonies}) {
    final list = json[section];
    if (list is! List || list.isEmpty) {
      err(file, '$section missing');
      return;
    }
    final ids = <String>{};
    for (final raw in list.cast<Map>()) {
      final id = raw['id'];
      final k = '$section/$id';
      if (id is! String || !RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(id)) {
        err(file, 'bad id $id in $section');
        continue;
      }
      if (!ids.add(id)) err(k, 'duplicate id');
      final kind = RuleKind.values.where((x) => x.name == raw['kind']).firstOrNull;
      if (testimonies ? (kind == null || kind == RuleKind.exclude) : kind != RuleKind.minus) {
        err(k, testimonies ? 'kind must be plus or minus' : 'kind must be minus (a warning)');
      }
      final w = raw['weight'];
      if (w is! int || w < (testimonies ? 1 : 0)) err(k, 'weight missing');
      if (!horaryConditions.contains(raw['when'])) err(k, 'unknown condition ${raw['when']}');
      if (raw['text'] != 'horary/$prefix/$id') err(k, 'text must be horary/$prefix/$id');
      if (!keys.contains('horary/$prefix/$id')) err(k, 'no content key horary/$prefix/$id (keys.dart)');
      if ((raw['about'] as String? ?? '').trim().isEmpty) err(k, 'empty about');
      if ((raw['source'] as String? ?? '').trim().isEmpty) err(k, 'empty source');
      if (raw['params'] != null && raw['params'] is! Map) err(k, 'params must be an object');
    }
    for (final r in expected) {
      if (!ids.contains(r)) err('$section/$r', 'listed in keys.dart but missing in the rule file');
    }
  }

  rules('considerations', 'consideration', horaryConsiderationIds, testimonies: false);
  rules('testimonies', 'testimony', horaryTestimonyIds, testimonies: true);

  final timing = (json['timing'] as Map?)?['units'];
  if (timing is! Map) {
    err(file, 'timing.units missing');
  } else {
    for (final a in HouseKind.values) {
      for (final b in HouseKind.values.where((b) => b.index >= a.index)) {
        final k = HoraryBook.timingKey(a, b);
        if (!horaryTimingIds.contains(timing[k])) err('timing/$k', 'unit must be one of ${horaryTimingIds.join(', ')}');
      }
    }
  }
  final lost = json['lost'];
  final signs = lost is Map ? lost['signs'] : null;
  final houses = lost is Map ? lost['houses'] : null;
  for (final s in Sign.values) {
    if (signs is! Map || (signs[s.name] as String? ?? '').isEmpty) err('lost/${s.name}', 'direction missing');
  }
  for (var h = 1; h <= 12; h++) {
    if (houses is! Map || (houses['$h'] as String? ?? '').isEmpty) err('lost_house/$h', 'direction missing');
  }
  return out;
}
