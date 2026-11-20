import 'dart:convert';
import 'dart:io';

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
      case 'transit_modifier':
        return (title: 'Modifikátor tranzitu: ${p[1]}', facts: 'Krátká vložená věta o fázi tranzitu: ${p[1]}');
      case 'glossary':
        return (title: 'Heslo slovníčku: ${p[1]}', facts: 'Vysvětli astrologický pojem ${p[1]} pro laika.');
      // R2 (plan 10.2): Moon and planetary hours.
      case 'planetary_hour':
        return (
          title: 'Hodina planety ${pn(p[1])}',
          facts: 'Planetární hodina (dvanáctina dne nebo noci, tradice podle chaldejského pořadí), které vládne: ${_planet(p[1])}\n'
              'Krátký text o tom, k čemu se taková hodina podle tradice hodí a čemu se vyhnout.'
        );
      case 'planetary_day':
        return (
          title: 'Den planety ${pn(p[1])}',
          facts: 'Planetární den (od východu do východu Slunce, vládce dne v týdnu): ${_planet(p[1])}\nRáz celého dne.'
        );
      case 'moon_phase':
        return (title: 'Fáze Měsíce: ${_phaseCz[p[1]]}', facts: 'Dnešní fáze Měsíce. ${_phaseCz[p[1]]}: ${_phaseCore[p[1]]}. Ráz dnů v této fázi.');
      case 'natal_moon_phase':
        return (
          title: 'Narození ve fázi: ${_phaseCz[p[1]]}',
          facts: 'Fáze Měsíce při narození (osm typů lunačního cyklu). ${_phaseCz[p[1]]}: ${_phaseCore[p[1]]}. Povaha člověka narozeného v této fázi.'
        );
      case 'moon_today':
        return (title: 'Měsíc dnes ${_s(p[1])['in']}', facts: 'Tranzitující Měsíc (nálada dne, 2–3 dny): ${_planet('moon')}\n${_sign(p[1])}');
      case 'lunation_in_house':
        final what = p[1] == 'new' ? 'Nov (začátek, setba)' : 'Úplněk (vrchol, sklizeň, napětí protikladů)';
        return (title: '${p[1] == 'new' ? 'Nov' : 'Úplněk'} v ${p[2]}. domě', facts: 'Lunace v natálním domě: $what.\n${_house(p[2])}');
      case 'void_of_course':
        return (
          title: 'Měsíc bez aspektu',
          facts: 'Měsíc bez kurzu: od posledního hlavního aspektu ve znamení do vstupu do dalšího znamení. Tradice radí nic nového nezačínat.'
        );
      case 'eclipse':
        final solar = p[1] == 'solar';
        return (
          title: solar ? 'Zatmění Slunce' : 'Zatmění Měsíce',
          facts: solar
              ? 'Zatmění Slunce: nov blízko lunárního uzlu, silný začátek, zakrytí vědomé vůle.'
              : 'Zatmění Měsíce: úplněk blízko lunárního uzlu, vyvrcholení, zakrytí citu a minulosti.'
        );
      case 'star':
        final st = a['stars'][p[1]] as Map<String, dynamic>;
        return (
          title: 'Stálice ${st['name']}',
          facts: 'Stálice ${st['name']}: ${st['place']}. Povaha podle Ptolemaia: ${st['nature']}.\n'
              'Počítá se jen konjunkce s planetou nebo osou v orbu 1° podle ekliptikální délky.'
        );
      case 'star_target':
        final pt = a['points'][p[1]] as Map<String, dynamic>?;
        final name = pt?['name'] ?? pn(p[1]);
        final facts = pt != null ? 'Bod ${pt['name']}: ${pt['core']}.' : _planet(p[1]);
        return (title: 'Stálice u bodu $name', facts: '$facts\nJedna věta o tom, co znamená, když na tomto bodě leží stálice.');
    }
    throw ArgumentError(key);
  }

  static const _phaseCz = {
    'new': 'nov', 'crescent': 'dorůstající srpek', 'first_quarter': 'první čtvrť', 'gibbous': 'dorůstající Měsíc před úplňkem',
    'full': 'úplněk', 'disseminating': 'couvající Měsíc po úplňku', 'last_quarter': 'poslední čtvrť', 'balsamic': 'ubývající srpek před novem',
  };
  static const _phaseCore = {
    'new': 'impuls, začátek, jednání bez odstupu',
    'crescent': 'prosazení nového proti setrvačnosti starého',
    'first_quarter': 'krize jednání, rozhodnutí, stavba',
    'gibbous': 'zdokonalování, rozbor, příprava na vrchol',
    'full': 'vyvrcholení, uvědomění, vztah a protiklad',
    'disseminating': 'předávání, šíření toho, co se ukázalo',
    'last_quarter': 'krize přesvědčení, přehodnocení, odklon',
    'balsamic': 'dozrání, uzavírání, odevzdání, semeno budoucího',
  };

  String _elementCz(String e) => {'fire': 'oheň', 'earth': 'země', 'air': 'vzduch', 'water': 'voda'}[e] ?? e;

  String build(String key) {
    final d = describe(key);
    final len = lengthRange(key);
    final family = familyOf(key);
    final noShadow = shadowExempt.contains(family);
    final traitList = traits.map((t) => '${t.id} (${t.name})').join(', ');
    final textRule = family == 'star'
        ? '- "text": 40–80 slov: kde hvězda leží, její mýtus a povaha podle planet. Celý text\n'
            '  včetně stínu a těžkých pasáží má 150–250 slov; tradiční výroky patří do stínu a "hard".\n'
            '  Moderní psychologický přepis nevydávej za tradici.'
        : family == 'star_target'
            ? '- "text": ${len.min}–${len.max} slov: jedna až dvě věty o tom, které oblasti života hvězda na tomto bodě zasahuje.'
            : '- "text": ${len.min}–${len.max} slov: povaha, nadání, projevy.';
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
$textRule
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
