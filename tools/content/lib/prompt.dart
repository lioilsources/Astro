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
      case 'synastry':
        final same = p[1] == p[2];
        return (
          title: same ? '${pn(p[1])} a ${pn(p[2])}: ${_qualityName(p[3])}' : '${pn(p[1])} – ${pn(p[2])}: ${_qualityName(p[3])}',
          facts: 'Srovnání horoskopů dvou lidí. ${same ? 'Tatáž planeta u obou' : 'Planeta jednoho z vás a planeta druhého'}:\n'
              '${_planet(p[1])}${same ? '' : '\n${_planet(p[2])}'}\nDruh: ${_qualityName(p[3])}.',
        );
      case 'synastry_point':
        final pt = a['points'][p[1]] as Map<String, dynamic>;
        return (
          title: '${pn(p[2])} a ${pt['name']} druhého: ${_qualityName(p[3])}',
          facts: 'Srovnání horoskopů dvou lidí: planeta jednoho z vás a osa druhého.\n${_planet(p[2])}\n'
              'Bod ${pt['name']} druhého: ${pt['core']}.\nDruh: ${_qualityName(p[3])}.',
        );
      case 'synastry_house':
        return (
          title: '${pn(p[1])} v ${p[2]}. domě druhého',
          facts: 'Srovnání horoskopů dvou lidí: planeta jednoho z vás padne do domu druhého.\n${_planet(p[1])}\n${_house(p[2])}',
        );
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
      // R5 (plan 10.5): secondary progressions and solar returns.
      case 'progressed':
        return _progressed(p);
      case 'solar_return':
        return _solarReturn(p);
      case 'journal':
        final j = _journal[p[1]]!;
        return (
          title: j.title,
          facts: 'Deník předpovědí: uživatel hodnotí své dny −2 až +2 a appka porovnává hodnocení se skóre napětí '
              'tranzitů. ${j.facts}\nPravidla navíc: nikdy slovo "důkaz"; výsledek "žádná souvislost" je stejně '
              'platný jako opačný; žádná čísla (doplní je appka), text se zobrazí pod větou s čísly.',
        );
    }
    throw ArgumentError(key);
  }

  static const _progressedIntro =
      'Sekundární progrese: den po narození odpovídá roku života. Popisuje pomalý vnitřní vývoj, ne vnější události.';

  ({String title, String facts}) _progressed(List<String> p) {
    String pn(String id) => _p(id)['name'] as String;
    switch (p[1]) {
      case 'moon_in_sign':
        return (
          title: 'Progresní Měsíc ${_s(p[2])['in']}',
          facts: '$_progressedIntro\nProgresní Měsíc (citové těžiště období asi 2,5 roku): ${_planet('moon')}\n${_sign(p[2])}\n'
              'Popiš, jak se v těch letech mění nálada, potřeby a to, co člověka citově živí.'
        );
      case 'moon_in_house':
        return (
          title: 'Progresní Měsíc v ${p[2]}. domě',
          facts: '$_progressedIntro\nProgresní Měsíc prochází natálním domem asi 2,5 roku: ${_planet('moon')}\n${_house(p[2])}\n'
              'Popiš, kam se v těch letech stáčí pozornost a citová energie.'
        );
      case 'sun_in_sign':
        return (
          title: 'Progresní Slunce ${_s(p[2])['in']}',
          facts: '$_progressedIntro\nProgresní Slunce mění znamení jednou za 30 let, je to dlouhá životní kapitola: ${_planet('sun')}\n${_sign(p[2])}'
        );
      case 'lunar_phase':
        return (
          title: 'Progresní fáze: ${_phaseCz[p[2]]}',
          facts: '$_progressedIntro\nProgresní lunační cyklus trvá 29,5 roku, každá z osmi fází asi 3,7 roku. '
              '${_phaseCz[p[2]]}: ${_phaseCore[p[2]]}. Ráz tohoto životního období.'
        );
      case 'modifier':
        final applying = p[2] == 'applying';
        return (
          title: 'Úvod progresního aspektu: ${applying ? 'sbíhá se' : 'rozbíhá se'}',
          facts: 'Jedna krátká úvodní věta před textem tranzitu ${pn('sun')}–${pn('pluto')}, který se znovu použije pro progresi. '
              'Řekne, že nejde o krátký tranzit, ale o pomalý vnitřní proces na roky, který se ${applying ? 'teprve blíží vrcholu' : 'už vyznívá'}.'
        );
    }
    throw ArgumentError(p.join('/'));
  }

  static const _angleCz = {
    'asc': ('ascendent', 'jak do roku vstupuješ, tělo, nový začátek'),
    'ic': ('IC (dno nebe)', 'domov, rodina, kořeny'),
    'dsc': ('descendent', 'partneři, protějšky, otevření nepřátelé'),
    'mc': ('MC (střed nebe)', 'práce, postavení, veřejné cíle'),
  };

  ({String title, String facts}) _solarReturn(List<String> p) {
    const intro = 'Solár: horoskop okamžiku, kdy se Slunce vrátí na natální délku. Platí na jeden rok, od narozenin do narozenin.';
    switch (p[1]) {
      case 'asc':
        return (title: 'Ascendent soláru ${_s(p[2])['in']}', facts: '$intro\nAscendent soláru: ráz a přístup celého roku.\n${_sign(p[2])}');
      case 'sun_in_house':
        return (title: 'Slunce soláru v ${p[2]}. domě', facts: '$intro\nDům Slunce soláru: hlavní oblast roku.\n${_house(p[2])}');
      case 'planet_on_angle':
        final (name, core) = _angleCz[p[3]]!;
        return (
          title: '${_p(p[2])['name']} na ose soláru: $name',
          facts: '$intro\nPlaneta do 5° od osy soláru zabarví celý rok.\n${_planet(p[2])}\nOsa $name: $core.'
        );
    }
    throw ArgumentError(p.join('/'));
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


  /// Prediction journal texts (plan 10.3).
  static const _journal = {
    'method': (
      title: 'Jak deník vyhodnocuje',
      facts: 'Vysvětli metodu: pořadová korelace napětí a hodnocení, test proti náhodě přeházením celých týdnů '
          '10 000×, kontrola horoskopy dvaceti cizích osob. Hypotéza zapsaná předem, záznam bez přepisování.'
    ),
    'too_few': (title: 'Zatím málo dat', facts: 'Ohodnocených dní je méně než 60; vysvětli, proč na vyhodnocení ještě nestačí.'),
    'relation_expected': (
      title: 'Napjaté dny vycházejí hůř',
      facts: 'Ve dnech s vyšším napětím hodnotí uživatel den hůř, a to víc, než dávají náhodná přeházení. '
          'Je to souvislost, ne příčina; vysvětli, co ji může způsobit (očekávání, náhoda, pár výrazných týdnů).'
    ),
    'relation_opposite': (
      title: 'Napjaté dny vycházejí líp',
      facts: 'Ve dnech s vyšším napětím hodnotí uživatel den lépe, opak toho, co čeká tradice.'
    ),
    'no_relation': (
      title: 'Souvislost se neukázala',
      facts: 'Hodnocení dní nesouvisí se skóre napětí víc než při náhodném přeházení týdnů. '
          'Je to platný a důležitý výsledek, ne selhání deníku.'
    ),
    'control_better': (
      title: 'Vlastní horoskop sedí líp než cizí',
      facts: 'Tranzity k vlastnímu horoskopu odpovídají hodnocení lépe než tranzity k horoskopům cizích osob z katalogu.'
    ),
    'control_not_better': (
      title: 'Cizí horoskopy sedí stejně dobře',
      facts: 'Tranzity k cizím horoskopům odpovídají hodnocení stejně dobře nebo lépe; shoda tedy není vázaná na vlastní horoskop.'
    ),
    'hypothesis_more': (
      title: 'Hypotéza: štítek častěji při tranzitu',
      facts: 'Ve dnech s tranzitem z hypotézy dává uživatel štítek častěji než ve dnech bez něj, víc, než by čekala náhoda.'
    ),
    'hypothesis_not_more': (
      title: 'Hypotéza: štítek ne častěji',
      facts: 'Ve dnech s tranzitem z hypotézy se štítek neobjevuje častěji než jindy (nebo rozdíl nepřesahuje náhodu).'
    ),
    'blind': (
      title: 'Slepý test',
      facts: 'Dobrovolný režim na 90 dní: pohled na tranzity se odemkne až po ohodnocení dne, aby předpověď neovlivnila '
          'hodnocení. Hodnocení mimo test se vyhodnocují zvlášť.'
    ),
  };
  String _qualityName(String q) =>
      {'conjunction': 'konjunkce', 'harmonious': 'harmonický aspekt (sextil, trigon)', 'tense': 'napěťový aspekt (kvadrát, opozice)'}[q] ?? q;

  String _elementCz(String e) => {'fire': 'oheň', 'earth': 'země', 'air': 'vzduch', 'water': 'voda'}[e] ?? e;

  String build(String key) {
    final d = describe(key);
    final len = lengthRange(key);
    final family = familyOf(key);
    final noShadow = isShadowExempt(key);
    final traitList = traits.map((t) => '${t.id} (${t.name})').join(', ');
    final pair = partnerFamilies.contains(family);
    final textRule = pair
        ? '- "text": ${len.min}–${len.max} slov: co se mezi vámi děje, kde se doplňujete, co si navzájem dáváte.\n'
            '  Text platí pro jakýkoli vztah: partneři, rodič a dítě, sourozenci, přátelé, kolegové.\n'
            '  Žádná romantika, erotika, přitažlivost ani intimita v "text", "shadow", "hard",\n'
            '  "title" ani "keywords"; to patří jen do pole "partner".\n'
            '- "partner": 30–80 slov: přitažlivost a intimita, jen pro milostný pár. Appka ho\n'
            '  ukáže pouze u typu vztahu partner, u rodiče a dítěte nikdy.'
        : family == 'star'
        ? '- "text": 40–80 slov: kde hvězda leží, její mýtus a povaha podle planet. Celý text\n'
            '  včetně stínu a těžkých pasáží má 150–250 slov; tradiční výroky patří do stínu a "hard".\n'
            '  Moderní psychologický přepis nevydávej za tradici.'
        : family == 'star_target'
            ? '- "text": ${len.min}–${len.max} slov: jedna až dvě věty o tom, které oblasti života hvězda na tomto bodě zasahuje.'
            : family == 'journal'
                ? '- "text": ${len.min}–${len.max} slov: věcné vysvětlení výsledku pro laika, bez astrologického výkladu povahy.'
                : '- "text": ${len.min}–${len.max} slov: povaha, nadání, projevy.';
    return '''
Napiš český text astrologického výkladu pro mobilní appku.

POSTAVENÍ: ${d.title}
VÝZNAMY (ručně psaná tabulka archetypů, rozviň je vlastními slovy):
${d.facts}

PRAVIDLA:
${pair ? '- Oslovuj oba: 2. osoba množného čísla ("mezi vámi", "máte"), přítomný čas.\n  "Jeden z vás", "druhý" místo jmen. Bez rodových tvarů ("byli jste" ne).\n' : ''}- 2. osoba, tykání, přítomný čas. Bez rodových tvarů: žádné "jsi citlivý/citlivá",
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
{"key": "$key", "title": "${d.title}", "keywords": [], "themes": [], "text": "", "shadow": "", "hard": [], "traits": {"text": [], "shadow": []}${pair ? ', "partner": ""' : ''}}
''';
  }
}
