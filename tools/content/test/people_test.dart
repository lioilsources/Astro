import 'dart:convert';
import 'dart:io';

import 'package:astro_content/people.dart';
import 'package:test/test.dart';

Map<String, dynamic> record({String? time, String rel = 'A', Map<String, dynamic>? source}) => {
      'id': 'x',
      'name': 'X',
      'living': false,
      'categories': ['history'],
      'reliability': rel,
      'source': source ?? {'note': 'birth record', 'url': 'https://example.org'},
      'birth': {'date': '1769-08-15', 'calendar': 'gregorian', 'time': time, 'time_basis': 'lmt', 'lat': 41.92, 'lon': 8.74},
      'events': [],
    };

void main() {
  test('committed catalog is valid', () {
    final list = (jsonDecode(File('../../content/people/people.json').readAsStringSync()) as List).cast<Map<String, dynamic>>();
    expect(validatePeople(list), isEmpty);
  });

  test('a record without source is rejected', () {
    expect(validatePeople([record(time: '11:30', source: {'note': '', 'url': ''})]), isNotEmpty);
  });

  test('no time requires grade X, a time forbids it', () {
    expect(validatePeople([record(time: null, rel: 'A')]), isNotEmpty);
    expect(validatePeople([record(time: null, rel: 'X')]), isEmpty);
    expect(validatePeople([record(time: '11:30', rel: 'X')]), isNotEmpty);
    expect(validatePeople([record(time: '11:30')]), isEmpty);
  });
}
