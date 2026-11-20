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

  group('events', () {
    Map<String, dynamic> ev(Map<String, dynamic> over) => {
          'date': '1815-06-18',
          'label': 'bitva u Waterloo',
          'type': 'battle',
          'defining': true,
          'source': 'Wikipedia: Napoleon',
          'url': 'https://en.wikipedia.org/wiki/Napoleon',
          'quote': 'On 18 June 1815 the armies met at Waterloo.',
          ...over,
        };

    test('a sourced day-precise defining event passes', () {
      expect(validateEvent(ev({}), '1769-08-15'), isEmpty);
      expect(validateEvent(ev({'quote': 'The battle took place on June 18, 1815, near Brussels.'}), '1769-08-15'), isEmpty);
    });

    test('dates must be real days within the life', () {
      expect(validateEvent(ev({'date': '1815-06'}), '1769-08-15'), isNotEmpty);
      expect(validateEvent(ev({'date': '1815-02-30', 'quote': '30 February 1815'}), '1769-08-15'), isNotEmpty);
      expect(validateEvent(ev({'date': '1760-06-18', 'quote': '18 June 1760'}), '1769-08-15'), isNotEmpty);
    });

    test('a Wikipedia event must quote the sentence with its date', () {
      expect(validateEvent(ev({'quote': ''}), '1769-08-15'), isNotEmpty);
      expect(validateEvent(ev({'quote': 'In June 1815 the armies met.'}), '1769-08-15'), isNotEmpty);
      expect(validateEvent(ev({'url': 'https://example.org'}), '1769-08-15'), isNotEmpty);
      // Julian-calendar sources: the sentence writes the Julian date, the event carries the Gregorian one.
      expect(
          validateEvent(ev({'date': '1355-04-13', 'date_julian': '1355-04-05', 'quote': 'He was crowned on 5 April 1355 in Rome.'}), '1316-05-14'),
          isEmpty);
    });

    test('defining flag and type', () {
      expect(validateEvent(ev({'defining': 'yes'}), '1769-08-15'), isNotEmpty);
      expect(validateEvent(ev({'type': 'party'}), '1769-08-15'), isNotEmpty);
      final wd = {'date': '1804-12-02', 'label': 'korunovace', 'type': 'coronation', 'defining': true, 'source': 'Wikidata Q517 P793 Q1', 'url': 'https://www.wikidata.org/wiki/Q517#P793'};
      expect(validateEvent(wd, '1769-08-15'), isEmpty);
      expect(validateEvent({...wd, 'url': null}, '1769-08-15'), isNotEmpty);
      expect(validateEvent({...wd, 'source': 'Wikidata'}, '1769-08-15'), isNotEmpty);
      // Old records without type and flag stay valid as ordinary events.
      expect(validateEvent({'date': '1796-03-09', 'label': 'sňatek', 'source': 'Wikidata Q517 P26'}, '1769-08-15'), isEmpty);
    });

    test('every catalog person has at least two defining events', () {
      final list = (jsonDecode(File('../../content/people/people.json').readAsStringSync()) as List).cast<Map<String, dynamic>>();
      final few = definingCounts(list).entries.where((e) => e.value < 2).map((e) => e.key).toList();
      expect(few, isEmpty);
    });
  });
}
