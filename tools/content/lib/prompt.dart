import 'dart:convert';
import 'dart:io';

import 'package:astro_core/astro_core.dart' show hemisphereMin, modalityExcessMin, modalityLackMax;

import 'schema.dart';

/// Builds the generation prompt for one key from the archetype table and style rules.
class PromptBuilder {
  final Map<String, dynamic> a;
  final List<Trait> traits;
  PromptBuilder(this.a, this.traits);

  factory PromptBuilder.load(Directory contentRoot) => PromptBuilder(
        jsonDecode(File('${contentRoot.path}/archetypes.cs.json').readAsStringSync()) as Map<String, dynamic>,
        loadTraits(Directory('${contentRoot.path}/cs')),
      );

  Map<String, dynamic> _p(String id) => a['planets'][id] as Map<String, dynamic>;
  Map<String, dynamic> _s(String id) => a['signs'][id] as Map<String, dynamic>;
  Map<String, dynamic> _h(String n) => a['houses'][n] as Map<String, dynamic>;
  Map<String, dynamic> _asp(String id) => a['aspects'][id] as Map<String, dynamic>;

  String _planet(String id) {
    final p = _p(id);
    return '${p['name']}: ${p['core']}. Stín: ${p['shadow']}. Tradice o těžkém: ${p['hard']}.';
  }

  String _sign(String id) {
    final s = _s(id);
    return '${s['name']} (${s['element']}, ${s['modality']}): ${s['core']}. Stín: ${s['shadow']}.';
  }

  String _house(String n) => '$n. dům: ${_h(n)['area']}. Tradice o těžkém: ${_h(n)['hard']}.';

  /// Title and the factual description of the position.
  ({String title, String facts}) describe(String key) {
    final p = key.split('/');
    String pn(String id) => _p(id)['name'] as String;
    String sn(String id) => _s(id)['name'] as String;
    switch (p.first) {
      case 'planet_in_sign':
        return (title: '${pn(p[1])} ${_s(p[2])['in']}', facts: '${_planet(p[1])}\n${_sign(p[2])}');
      case 'planet_in_house':
        return (title: '${pn(p[1])} v ${p[2]}. domě', facts: '${_planet(p[1])}\n${_house(p[2])}');
      case 'aspect':
        return (
          title: '${pn(p[1])} ${_asp(p[3])['name']} ${pn(p[2])}',
          facts: '${_planet(p[1])}\n${_planet(p[2])}\nAspekt ${_asp(p[3])['name']}: ${_asp(p[3])['core']}.'
        );
      case 'aspect_point':
      case 'transit_point':
        final pt = a['points'][p[p.first == 'aspect_point' ? 1 : 2]] as Map<String, dynamic>;
        final planet = p.first == 'aspect_point' ? p[2] : p[1];
        final q = p[3];
        final qn = {'conjunction': 'konjunkce', 'harmonious': 'harmonický aspekt (sextil, trigon)', 'tense': 'napěťový aspekt (kvadrát, opozice)'}[q];
        final tr = p.first == 'transit_point' ? 'Tranzitující ' : '';
        return (title: '$tr${pn(planet)} – ${pt['name']}: $qn', facts: '${_planet(planet)}\nBod ${pt['name']}: ${pt['core']}.\nDruh: $qn.');
      case 'sign_on_cusp':
        final t = p[1] == '1' ? '${sn(p[2])} na ascendentu' : (p[1] == '10' ? '${sn(p[2])} na MC' : '${sn(p[2])} na hrotu ${p[1]}. domu');
        return (title: t, facts: '${_sign(p[2])}\n${_house(p[1])}');
      case 'transit':
        return (
          title: 'Tranzitující ${pn(p[1])} ${_asp(p[3])['name']} natální ${pn(p[2])}',
          facts: 'Tranzit (dočasné období): ${_planet(p[1])}\nNatální planeta: ${_planet(p[2])}\nAspekt ${_asp(p[3])['name']}: ${_asp(p[3])['core']}.'
        );
      case 'transit_in_house':
        return (title: 'Tranzitující ${pn(p[1])} v ${p[2]}. domě', facts: 'Tranzit (dočasné období): ${_planet(p[1])}\n${_house(p[2])}');
      case 'house_area':
        return (title: '${p[1]}. dům', facts: _house(p[1]));
      case 'emphasis':
        final kind = p[1];
        final v = p[2];
        final what = switch (kind) {
          'sign' => 'tři a více planet ve znamení ${_sign(v)}',
          'house' => 'tři a více planet v domě: ${_house(v)}',
          'element_dominant' => 'převládá živel ${_elementCz(v)}',
          _ => 'chybí živel ${_elementCz(v)} (žádná planeta)',
        };
        return (title: 'Přemíra a nedostatek: $what', facts: what);
      case 'pattern':
        return _pattern(p);
      case 'transit_modifier':
        return (title: 'Modifikátor tranzitu: ${p[1]}', facts: 'Krátká vložená věta o fázi tranzitu: ${p[1]}');
      case 'glossary':
        return (title: 'Heslo slovníčku: ${p[1]}', facts: 'Vysvětli astrologický pojem ${p[1]} pro laika.');
    }
    throw ArgumentError(key);
  }

  /// Aspect patterns and balances (plan 10.1).
  ({String title, String facts}) _pattern(List<String> p) {
    final pa = a['patterns'] as Map<String, dynamic>;
    Map<String, dynamic> shape(String id) => pa['shapes'][id] as Map<String, dynamic>;
    String shapeFacts(String id) {
      final s = shape(id);
      return 'Obrazec ${s['name']}: ${s['core']}. Stín: ${s['shadow']}. Tradice o těžkém: ${s['hard']}.';
    }

    String element(String id) {
      final e = pa['elements'][id] as Map<String, dynamic>;
      final signs = [
        for (final s in signIds.map(_s))
          if (s['element'] == e['name']) s['name'],
      ];
      return 'Živel ${e['name']} (${signs.join(', ')}): ${e['core']}.';
    }

    String modality(String id) {
      final m = pa['modalities'][id] as Map<String, dynamic>;
      return 'Kvalita ${m['name']}: ${m['core']}. Stín: ${m['shadow']}.';
    }

    String name(String id) => shape(id)['name'] as String;
    String cap(String s) => s[0].toUpperCase() + s.substring(1);
    final planet = p.length > 2 ? a['planets'][p[2]] as Map<String, dynamic>? : null;
    final pn = planet == null ? null : planet['name'];
    switch (p[1]) {
      case 'grand_trine' || 'kite':
        return (title: '${cap(name(p[1]))} v živlu ${pa['elements'][p[2]]['name']}', facts: '${shapeFacts(p[1])}\n${element(p[2])}');
      case 't_square' || 'grand_cross':
        return (title: '${cap(pa['modalities'][p[2]]['masc'] as String)} ${name(p[1])}', facts: '${shapeFacts(p[1])}\n${modality(p[2])}');
      case 't_square_apex' || 'yod_apex':
        final whole = p[1] == 't_square_apex' ? 't_square' : 'yod';
        return (
          title: '$pn na vrcholu ${p[1] == 't_square_apex' ? 'T-kvadrátu' : 'jodu'}',
          facts: '${shapeFacts(whole)}\n${shapeFacts(p[1])}\n${_planet(p[2])}',
        );
      case 'cradle' || 'mystic_rectangle':
        return (title: cap(name(p[1])), facts: shapeFacts(p[1]));
      case 'modality':
        final m = pa['modalities'][p[2]] as Map<String, dynamic>;
        final excess = p[3] == 'excess';
        final what = excess
            ? '$modalityExcessMin a více z deseti planet ve znameních kvality ${m['name']}'
            : 'nejvýš $modalityLackMax z deseti planet ve znameních kvality ${m['name']}';
        return (
          title: '${excess ? 'Přemíra' : 'Nedostatek'} ${m['plural']} znamení',
          facts:
              'Rovnováha kvalit: $what.\n${modality(p[2])}\n${excess ? 'Kvalita převládá a barví celou povahu.' : 'Kvalita chybí; její schopnosti je třeba hledat jinde nebo se jim učit.'}',
        );
      case 'hemisphere':
        final h = pa['hemispheres'][p[2]] as Map<String, dynamic>;
        return (title: 'Důraz na ${h['acc']}', facts: '$hemisphereMin a více z deseti planet leží v polokouli: ${h['name']}. Význam: ${h['core']}.');
      case 'unaspected':
        return (title: '$pn bez aspektu', facts: '${shapeFacts('unaspected')}\n${_planet(p[2])}');
    }
    throw ArgumentError(p.join('/'));
  }


  String _elementCz(String e) => {'fire': 'oheň', 'earth': 'země', 'air': 'vzduch', 'water': 'voda'}[e] ?? e;

  String build(String key) {
    final d = describe(key);
    final len = lengthRange(key);
    final family = familyOf(key);
    final noShadow = shadowExempt.contains(family);
    final traitList = traits.map((t) => '${t.id} (${t.name})').join(', ');
    return '''
Napiš český text astrologického výkladu pro mobilní appku.

POSTAVENÍ: ${d.title}
VÝZNAMY (ručně psaná tabulka archetypů, rozviň je vlastními slovy):
${d.facts}

PRAVIDLA:
- 2. osoba, tykání, přítomný čas. Bez rodových tvarů: žádné "jsi citlivý/citlivá",
  "byl jsi", "mohla bys". Použij podstatná jména nebo slovesa ("máš citlivou povahu").
- Krátké konkrétní věty, žádné fráze o hvězdách, žádné rady k léčbě, penězům ani právu.
- První věta textu i stínu patří jen téhle kombinaci. Žádná obecná věta o znamení
  nebo planetě ("Stálost se snadno mění v…"), kterou by šlo dát i jiné planetě.
- Žádné "sám/sama", "rád/ráda" o čtenáři; "sám o sobě" o věci je v pořádku.
- Úplný tradiční výklad. Nic nevynechávej ani nezměkčuj, včetně smrti a nemocí.
  Těžká témata věcně a s uvozením "tradice tu mluví o…", nikdy jako jistota.
- "text": ${len.min}–${len.max} slov: povaha, nadání, projevy.
${noShadow ? '- "shadow": prázdný řetězec.' : '- "shadow": 40–100 slov: slabiny a odvrácená strana téhož.'}
- "hard": seznam pasáží o těžkých tématech, jen kde tradice něco říká; každá má
  "topics" z výčtu ${hardTopics.join(', ')} a "text" 20–80 slov.
- "keywords": 3–5 hesel malými písmeny. "themes": z výčtu ${themeIds.join(', ')}.
- "traits": {"text": [...], "shadow": [...]} — 2–5 id na vrstvu, jen z tohoto slovníku:
  $traitList

Odpověz jen JSON objektem:
{"key": "$key", "title": "${d.title}", "keywords": [], "themes": [], "text": "", "shadow": "", "hard": [], "traits": {"text": [], "shadow": []}}
''';
  }
}
