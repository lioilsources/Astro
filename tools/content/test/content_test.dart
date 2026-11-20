import 'dart:io';

import 'package:astro_content/prompt.dart';
import 'package:astro_content/schema.dart';
import 'package:astro_content/validate.dart';
import 'package:test/test.dart';

void main() {
  final dir = Directory('../../content/cs');

  test('key families have the sizes from the plan', () {
    final k = allKeysByFamily();
    expect(k['planet_in_sign']!.length, 132);
    expect(k['planet_in_house']!.length, 132);
    expect(k['aspect']!.length, 225);
    expect(k['aspect_point']!.length, 90);
    expect(k['sign_on_cusp']!.length, 144);
    expect(k['transit']!.length, 500);
    expect(k['transit_point']!.length, 60);
    expect(k['transit_in_house']!.length, 120);
    expect(k['emphasis']!.length, 32);
    expect(k['star']!.length, 32);
    expect(k['star_target']!.length, 12);
  });

  test('star texts need no minimum base length, but the whole text is checked', () {
    const e = ContentEntry(
      key: 'star/algol',
      title: 'Algol',
      text: 'Algol leží v hlavě Medúzy.',
      shadow: 'Krátký stín.',
      hard: [HardPassage(['violence'], 'Násilí bez uvození.')],
    );
    final f = validate({e.key: e}, const []);
    expect(f.where((x) => x.error), isEmpty);
    expect(f.any((x) => x.message.startsWith('base layer')), isFalse);
    expect(f.any((x) => x.message.contains('150–250')), isTrue);
    expect(f.any((x) => x.message.contains('tradice tu mluví')), isTrue);
  });

  test('committed content has no errors', () {
    final findings = validate(loadEntries(dir), loadTraits(dir));
    expect(findings.where((f) => f.error), isEmpty, reason: findings.join('\n'));
  });

  test('validator catches bad hard topics, English and missing shadow', () {
    final bad = ContentEntry(
      key: 'aspect/sun/moon/square',
      title: 'x',
      text: 'This is the text and you are here with the Sun.',
      hard: const [HardPassage(['suicide'], 'Tradice tu mluví o něčem.')],
    );
    final f = validate({bad.key: bad}, loadTraits(dir));
    expect(f.where((x) => x.error).map((x) => x.message).join(' '), allOf(contains('English'), contains('hard topic'), contains('empty shadow')));
  });

  test('validator warns about gendered forms', () {
    const e = ContentEntry(key: 'aspect/sun/moon/trine', title: 'x', text: 'Jsi citlivý a máš rád klid.', shadow: 'Byl jsi unavený.');
    expect(validate({e.key: e}, const []).any((f) => f.message.contains('gendered')), isTrue);
  });

  test('every key can be turned into a prompt', () {
    final b = PromptBuilder.load(Directory('../../content'));
    for (final family in allKeysByFamily().values) {
      for (final key in family) {
        expect(b.build(key), contains(key));
      }
    }
  });
}
