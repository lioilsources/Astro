// Generates missing texts through an OpenAI-compatible endpoint (SPARK gateway via
// sparkctl lease) or the Anthropic API. Idempotent: done keys are skipped.
//
//   LLM_BASE_URL=… LLM_API_KEY=… LLM_MODEL=… dart run astro_content:generate --family aspect [--limit 20] [--keys k1,k2]
//   LLM_PROVIDER=anthropic ANTHROPIC_API_KEY=… LLM_MODEL=claude-opus-5-5 dart run astro_content:generate …
import 'dart:convert';
import 'dart:io';

import 'package:astro_content/prompt.dart';
import 'package:astro_content/schema.dart';
import 'package:astro_content/validate.dart';
import 'package:http/http.dart' as http;

Future<void> main(List<String> args) async {
  String? opt(String name) {
    final i = args.indexOf('--$name');
    return i >= 0 && i + 1 < args.length ? args[i + 1] : null;
  }

  final root = _repoRoot();
  final contentDir = Directory('${root.path}/content/cs');
  final builder = PromptBuilder.load(Directory('${root.path}/content'));
  final entries = loadEntries(contentDir);
  final family = opt('family');
  final limit = int.tryParse(opt('limit') ?? '') ?? 1 << 30;
  final explicit = opt('keys')?.split(',');
  final all = allKeysByFamily();
  final todo = (explicit ?? [for (final f in all.entries) if (family == null || f.key == family) ...f.value])
      .where((k) => !entries.containsKey(k))
      .take(limit)
      .toList();
  final env = Platform.environment;
  final provider = env['LLM_PROVIDER'] ?? 'openai';
  final model = env['LLM_MODEL'] ?? (provider == 'anthropic' ? 'claude-opus-5-5' : 'qwen36');
  stdout.writeln('${todo.length} texts to generate with $provider/$model');
  var ok = 0, failed = 0;
  for (final key in todo) {
    try {
      final raw = await _complete(provider, model, builder.build(key), env);
      final json = jsonDecode(_extractJson(raw)) as Map<String, dynamic>;
      json['key'] = key;
      json['meta'] = {'model': model, 'generated': DateTime.now().toUtc().toIso8601String().substring(0, 10)};
      final entry = ContentEntry.fromJson(json);
      final errors = validate({key: entry}, loadTraits(contentDir)).where((f) => f.error).toList();
      if (errors.isNotEmpty) throw FormatException(errors.join('; '));
      entries[key] = entry;
      final fam = familyOf(key);
      writeFamily(contentDir, fam, entries.values.where((e) => familyOf(e.key) == fam));
      ok++;
      stdout.writeln('ok   $key');
    } catch (e) {
      failed++;
      stdout.writeln('fail $key: $e');
    }
  }
  stdout.writeln(jsonEncode({'texts': {'ok': ok, 'failed': failed}}));
  if (failed > 0 && ok == 0) exit(1);
}

Future<String> _complete(String provider, String model, String prompt, Map<String, String> env) async {
  if (provider == 'anthropic') {
    final r = await http.post(Uri.parse('https://api.anthropic.com/v1/messages'),
        headers: {'x-api-key': env['ANTHROPIC_API_KEY']!, 'anthropic-version': '2023-06-01', 'content-type': 'application/json'},
        body: jsonEncode({'model': model, 'max_tokens': 4000, 'messages': [{'role': 'user', 'content': prompt}]}));
    if (r.statusCode != 200) throw HttpException('${r.statusCode} ${r.body}');
    return ((jsonDecode(utf8.decode(r.bodyBytes))['content'] as List).first as Map)['text'] as String;
  }
  final base = env['LLM_BASE_URL'] ?? (throw StateError('LLM_BASE_URL not set'));
  final r = await http.post(Uri.parse('$base/chat/completions'),
      headers: {'authorization': 'Bearer ${env['LLM_API_KEY'] ?? ''}', 'content-type': 'application/json'},
      body: jsonEncode({
        'model': model,
        'temperature': 0.7,
        'max_tokens': 4000,
        'response_format': {'type': 'json_object'},
        'messages': [{'role': 'user', 'content': prompt}],
      }));
  if (r.statusCode != 200) throw HttpException('${r.statusCode} ${r.body}');
  final body = jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>;
  final used = body['model'];
  if (used != null && !used.toString().contains(model)) {
    throw StateError('gateway answered with $used instead of $model (fallback?)');
  }
  return ((body['choices'] as List).first['message'] as Map)['content'] as String;
}

String _extractJson(String s) {
  final a = s.indexOf('{');
  final b = s.lastIndexOf('}');
  if (a < 0 || b < a) throw FormatException('no JSON object in answer');
  return s.substring(a, b + 1);
}

Directory _repoRoot() {
  var d = Directory.current;
  while (!File('${d.path}/content/archetypes.cs.json').existsSync() && d.parent.path != d.path) {
    d = d.parent;
  }
  return d;
}
