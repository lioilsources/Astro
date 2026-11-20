// dart run astro_content:people — validates content/people/people.json
import 'dart:convert';
import 'dart:io';

import 'package:astro_content/people.dart';

void main() {
  var d = Directory.current;
  while (!File('${d.path}/content/people/people.json').existsSync() && d.parent.path != d.path) {
    d = d.parent;
  }
  final records = (jsonDecode(File('${d.path}/content/people/people.json').readAsStringSync()) as List).cast<Map<String, dynamic>>();
  final errors = validatePeople(records);
  errors.forEach(print);
  print('${records.length} records, ${errors.length} errors');
  if (errors.isNotEmpty) exit(1);
}
