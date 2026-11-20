import 'dart:convert';
import 'dart:io';

import 'package:astro_core/astro_core.dart'
    show ElectionIntent, RuleKind, RuleLayer, electionConditions, electionVerdictIds;

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
