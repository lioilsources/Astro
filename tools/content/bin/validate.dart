// dart run astro_content:validate [--complete] [content/cs]
import 'dart:io';

import 'package:astro_content/schema.dart';
import 'package:astro_content/validate.dart';

void main(List<String> args) {
  final complete = args.contains('--complete');
  final dirArg = args.where((a) => !a.startsWith('--')).firstOrNull;
  final dir = Directory(dirArg ?? _defaultDir());
  final entries = loadEntries(dir);
  final findings = validate(entries, loadTraits(dir), requireComplete: complete);
  for (final f in findings) {
    print(f);
  }
  final errors = findings.where((f) => f.error).length;
  print('${entries.length} texts, $errors errors, ${findings.length - errors} warnings');
  if (errors > 0) exit(1);
}

String _defaultDir() {
  var d = Directory.current;
  while (!Directory('${d.path}/content/cs').existsSync() && d.parent.path != d.path) {
    d = d.parent;
  }
  return '${d.path}/content/cs';
}
