// Generates missing texts through an OpenAI-compatible endpoint (SPARK gateway via
// sparkctl lease) or the Anthropic API. Idempotent: done keys are skipped.
//
//   LLM_BASE_URL=… LLM_API_KEY=… LLM_MODEL=… dart run astro_content:generate --family aspect [--limit 20] [--keys k1,k2] [--jobs 6]
//   … --batch            Message Batches API (half price); --collect <id> resumes polling
//   LLM_PROVIDER=anthropic ANTHROPIC_API_KEY=… LLM_MODEL=claude-opus-5-5 dart run astro_content:generate …
//   … --layer advice     adds only the "Co s tím" layer to existing texts without it (plan R9 5.4)
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
  final adviceOnly = opt('layer') == 'advice';
  if (opt('layer') != null && !adviceOnly) throw ArgumentError('--layer supports only advice');
  final todo =
      (explicit ??
              [
                for (final f in all.entries)
                  if (family == null || f.key == family) ...f.value,
              ])
          .where((k) => adviceOnly
              ? entries[k] != null && adviceFamilies.contains(familyOf(k)) && entries[k]!.advice.trim().isEmpty
              : !entries.containsKey(k))
          .take(limit)
          .toList();
  final env = Platform.environment;
  final provider = env['LLM_PROVIDER'] ?? 'openai';
  final model =
      env['LLM_MODEL'] ??
      (provider == 'anthropic' ? 'claude-opus-5-5' : 'qwen36');
  stdout.writeln('${todo.length} texts to generate with $provider/$model');
  final jobs = int.tryParse(opt('jobs') ?? '') ?? 1;
  final traits = loadTraits(contentDir);
  final job = adviceOnly
      ? _Job((k) => builder.buildAdvice(entries[k]!), (k, raw, m) => _storeAdvice(k, raw, m, entries, contentDir, traits))
      : _Job(builder.build, (k, raw, m) => _store(k, raw, m, entries, contentDir, traits));
  final batchId = opt('collect');
  if (args.contains('--batch') || batchId != null) {
    if (provider != 'anthropic') {
      throw StateError('--batch needs LLM_PROVIDER=anthropic');
    }
    await _batch(batchId, todo, model, job, env, Directory('${root.path}/run'));
    return;
  }
  var ok = 0, failed = 0;
  final queue = todo.iterator;
  // Workers share one isolate, so the synchronous family writes never interleave.
  Future<void> worker() async {
    while (queue.moveNext()) {
      final key = queue.current;
      for (var attempt = 1; ; attempt++) {
        try {
          job.store(key, await _complete(provider, model, job.prompt(key), env), model);
          ok++;
          stdout.writeln('ok   $key');
          break;
        } catch (e) {
          if (attempt < 3) {
            await Future<void>.delayed(Duration(seconds: 20 * attempt));
            continue;
          }
          failed++;
          stdout.writeln('fail $key: $e');
          break;
        }
      }
    }
  }

  await Future.wait([for (var i = 0; i < jobs; i++) worker()]);
  stdout.writeln(
    jsonEncode({
      'texts': {'ok': ok, 'failed': failed},
    }),
  );
  if (failed > 0 && ok == 0) exit(1);
}

class _Job {
  final String Function(String key) prompt;
  final void Function(String key, String raw, String model) store;
  const _Job(this.prompt, this.store);
}

/// Merges an answer `{"key", "advice"}` into the existing entry, validates and writes it.
void _storeAdvice(
  String key,
  String raw,
  String model,
  Map<String, ContentEntry> entries,
  Directory contentDir,
  List<Trait> traits,
) {
  final json = jsonDecode(_extractJson(raw)) as Map<String, dynamic>;
  final advice = (json['advice'] as String? ?? '').trim();
  if (advice.isEmpty) throw const FormatException('empty advice');
  final entry = entries[key]!.withAdvice(advice);
  final errors = validate({key: entry}, traits).where((f) => f.error).toList();
  if (errors.isNotEmpty) throw FormatException(errors.join('; '));
  entries[key] = entry;
  final fam = familyOf(key);
  writeFamily(contentDir, fam, entries.values.where((e) => familyOf(e.key) == fam));
}

/// Parses, validates and writes one answer; throws on any problem.
void _store(
  String key,
  String raw,
  String model,
  Map<String, ContentEntry> entries,
  Directory contentDir,
  List<Trait> traits,
) {
  {
    {
      final json = jsonDecode(_extractJson(raw)) as Map<String, dynamic>;
      json['key'] = key;
      json['meta'] = {
        'model': model,
        'generated': DateTime.now().toUtc().toIso8601String().substring(0, 10),
      };
      final entry = ContentEntry.fromJson(json);
      final errors = validate({
        key: entry,
      }, traits).where((f) => f.error).toList();
      if (errors.isNotEmpty) throw FormatException(errors.join('; '));
      entries[key] = entry;
      final fam = familyOf(key);
      writeFamily(
        contentDir,
        fam,
        entries.values.where((e) => familyOf(e.key) == fam),
      );
    }
  }
}

Future<String> _complete(
  String provider,
  String model,
  String prompt,
  Map<String, String> env,
) async {
  if (provider == 'anthropic') {
    final r = await http.post(
      Uri.parse('https://api.anthropic.com/v1/messages'),
      headers: _anthropicHeaders(env),
      body: jsonEncode({
        'model': model,
        'max_tokens': 16000,
        'messages': [
          {'role': 'user', 'content': prompt},
        ],
      }),
    );
    if (r.statusCode != 200) throw HttpException('${r.statusCode} ${r.body}');
    return _textOf(
      jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>,
    );
  }
  final base =
      env['LLM_BASE_URL'] ?? (throw StateError('LLM_BASE_URL not set'));
  final r = await http.post(
    Uri.parse('$base/chat/completions'),
    headers: {
      'authorization': 'Bearer ${env['LLM_API_KEY'] ?? ''}',
      'content-type': 'application/json',
    },
    body: jsonEncode({
      'model': model,
      'temperature': 0.7,
      'max_tokens': 4000,
      'response_format': {'type': 'json_object'},
      'messages': [
        {'role': 'user', 'content': prompt},
      ],
    }),
  );
  if (r.statusCode != 200) throw HttpException('${r.statusCode} ${r.body}');
  final body = jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>;
  final used = body['model'];
  if (used != null && !used.toString().contains(model)) {
    throw StateError(
      'gateway answered with $used instead of $model (fallback?)',
    );
  }
  return ((body['choices'] as List).first['message'] as Map)['content']
      as String;
}

Map<String, String> _anthropicHeaders(Map<String, String> env) => {
  'x-api-key':
      env['ANTHROPIC_API_KEY'] ??
      (throw StateError('ANTHROPIC_API_KEY not set')),
  'anthropic-version': '2023-06-01',
  'content-type': 'application/json',
};

/// Message Batches API (half price, results within 24 h). Submits [todo], records the
/// batch in run/content-batch.json, polls until it ends and stores every answer.
/// `--collect <batch id>` resumes polling for an already submitted batch.
Future<void> _batch(
  String? batchId,
  List<String> todo,
  String model,
  _Job job,
  Map<String, String> env,
  Directory runDir,
) async {
  const api = 'https://api.anthropic.com/v1/messages/batches';
  final headers = _anthropicHeaders(env);
  final state = File('${runDir.path}/content-batch.json');
  Map<String, String>
  ids; // custom_id -> content key (keys contain '/', custom ids may not)
  if (batchId == null) {
    if (todo.isEmpty) return;
    ids = {for (final (i, k) in todo.indexed) 't$i': k};
    final r = await http.post(
      Uri.parse(api),
      headers: headers,
      body: jsonEncode({
        'requests': [
          for (final e in ids.entries)
            {
              'custom_id': e.key,
              'params': {
                'model': model,
                'max_tokens': 16000,
                'messages': [
                  {'role': 'user', 'content': job.prompt(e.value)},
                ],
              },
            },
        ],
      }),
    );
    if (r.statusCode != 200) throw HttpException('${r.statusCode} ${r.body}');
    batchId = (jsonDecode(r.body) as Map<String, dynamic>)['id'] as String;
    runDir.createSync(recursive: true);
    state.writeAsStringSync(jsonEncode({'id': batchId, 'ids': ids}));
    stdout.writeln('submitted batch $batchId with ${ids.length} requests');
  } else {
    final saved = jsonDecode(state.readAsStringSync()) as Map<String, dynamic>;
    if (saved['id'] != batchId) {
      throw StateError(
        'run/content-batch.json holds ${saved['id']}, not $batchId',
      );
    }
    ids = (saved['ids'] as Map).cast<String, String>();
  }
  Map<String, dynamic> info;
  while (true) {
    final r = await http.get(Uri.parse('$api/$batchId'), headers: headers);
    if (r.statusCode != 200) throw HttpException('${r.statusCode} ${r.body}');
    info = jsonDecode(r.body) as Map<String, dynamic>;
    stdout.writeln(
      '${DateTime.now().toIso8601String().substring(0, 19)} ${info['processing_status']} ${jsonEncode(info['request_counts'])}',
    );
    if (info['processing_status'] == 'ended') break;
    await Future<void>.delayed(const Duration(minutes: 2));
  }
  final res = await http.get(
    Uri.parse(info['results_url'] as String),
    headers: headers,
  );
  if (res.statusCode != 200) {
    throw HttpException('${res.statusCode} ${res.body}');
  }
  var ok = 0, failed = 0;
  final retry = <String>[];
  for (final line in const LineSplitter().convert(utf8.decode(res.bodyBytes))) {
    if (line.trim().isEmpty) continue;
    final item = jsonDecode(line) as Map<String, dynamic>;
    final key = ids[item['custom_id']]!;
    try {
      final result = item['result'] as Map<String, dynamic>;
      if (result['type'] != 'succeeded') {
        throw StateError('${result['type']} ${jsonEncode(result['error'])}');
      }
      job.store(key, _textOf(result['message'] as Map<String, dynamic>), model);
      ok++;
    } catch (e) {
      failed++;
      retry.add(key);
      stdout.writeln('fail $key: $e');
    }
  }
  if (retry.isNotEmpty) {
    File('${runDir.path}/content-retry.txt').writeAsStringSync(retry.join(','));
  }
  stdout.writeln(
    jsonEncode({
      'batch': batchId,
      'texts': {'ok': ok, 'failed': failed},
    }),
  );
}

String _textOf(Map<String, dynamic> body) {
  if (body['stop_reason'] == 'max_tokens') {
    throw StateError('answer truncated at max_tokens');
  }
  // Newer models may prepend thinking blocks; only text blocks carry the answer.
  final text = [
    for (final b in (body['content'] as List).cast<Map<String, dynamic>>())
      if (b['type'] == 'text') b['text'] as String,
  ].join();
  if (text.isEmpty) throw StateError('no text block in answer');
  return text;
}

String _extractJson(String s) {
  final a = s.indexOf('{');
  final b = s.lastIndexOf('}');
  if (a < 0 || b < a) throw FormatException('no JSON object in answer');
  return s.substring(a, b + 1);
}

Directory _repoRoot() {
  var d = Directory.current;
  while (!File('${d.path}/content/archetypes.cs.json').existsSync() &&
      d.parent.path != d.path) {
    d = d.parent;
  }
  return d;
}
