import 'dart:convert';
import 'dart:io';

import 'package:astro_core/astro_core.dart' show ElectionIntent, hemisphereMin, modalityExcessMin, modalityLackMax;

import 'rules.dart';
import 'schema.dart';

/// Builds the generation prompt for one key from the archetype table and style rules.
class PromptBuilder {
  final Map<String, dynamic> a;
  final List<Trait> traits;

  /// Election rules by id (`content/rules/election.json`), for `election/rule/…`.
  final Map<String, Map<String, Object?>> rules;
  /// Horary considerations and testimonies by `section/id` (`content/rules/horary.json`).
  final Map<String, Map<String, Object?>> horary;
  PromptBuilder(this.a, this.traits, {this.rules = const {}, this.horary = const {}});

  factory PromptBuilder.load(Directory contentRoot) => PromptBuilder(
        jsonDecode(File('${contentRoot.path}/archetypes.cs.json').readAsStringSync()) as Map<String, dynamic>,
        loadTraits(Directory('${contentRoot.path}/cs')),
        rules: {
          for (final r in (loadElectionRules(contentRoot)['rules'] as List).cast<Map>()) r['id'] as String: r.cast<String, Object?>(),
        },
        horary: {
          for (final section in ['testimonies', 'considerations'])
            for (final r in (loadHoraryRules(contentRoot)[section] as List).cast<Map>()) '$section/${r['id']}': r.cast<String, Object?>(),
          for (final e in (((loadHoraryRules(contentRoot)['lost'] as Map)['places'] as Map?) ?? const {}).entries)
            'places/${e.key}': {'place': e.value},
        },
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
      case 'pair_need':
        final need = (a['pair']['needs'] as Map)[p[1]] as Map<String, dynamic>;
        final sIn = _s(p[2])['in'] as String;
        return (
          title: p[1] == 'dsc' ? 'Descendent $sIn: koho hledá' : '${need['name']} $sIn: co potřebuje',
          facts: 'Průvodce vztahem: co člověk s tímto postavením potřebuje od blízkého člověka (partnera, rodiče, '
              'dítěte, sourozence, přítele, kolegy). Text čte ten druhý, aby mu to uměl dopřát.\n'
              'Bod: ${need['name']}, ve vztahu: ${need['in_relationship']}.\n${_sign(p[2])}',
        );
      case 'pair_elements':
        final pl = (a['pair']['needs'] as Map)[p[1]] as Map<String, dynamic>;
        final el = a['pair']['elements'] as Map<String, dynamic>;
        final same = p[2] == p[3];
        return (
          title: same ? '${pl['name']}: oba ${_elementCz(p[2])}' : '${pl['name']}: ${_elementCz(p[2])} a ${_elementCz(p[3])}',
          facts: 'Průvodce vztahem: ${pl['name']} jednoho z vás ve znamení živlu ${_elementCz(p[2])}, druhého ve znamení '
              'živlu ${_elementCz(p[3])}. ${pl['name']} ve vztahu: ${pl['in_relationship']}.\n'
              '${_elementCz(p[2])}: ${el[p[2]]}.${same ? '' : '\n${_elementCz(p[3])}: ${el[p[3]]}.'}',
        );
      case 'pair_period':
        final per = a['pair'] as Map<String, dynamic>;
        if (p[1] == 'cycle') {
          final c = (per['cycles'] as Map)[p[2]] as String;
          final name = c.split(':').first;
          return (
            title: '${name[0].toUpperCase()}${name.substring(1)}',
            facts: 'Průvodce vztahem, časová osa: období, kterým prochází jeden z vás a které se dotýká vztahu.\n'
                'Přelom života: $c.\n${_planet(p[2].split('_').first)}',
          );
        }
        const dative = {'sun': 'ke Slunci', 'moon': 'k Měsíci', 'venus': 'k Venuši', 'mars': 'k Marsu', 'axis': 'k ose vztahu'};
        final support = p[1] == 'jupiter';
        return (
          title: '${pn(p[1])} ${dative[p[2]]}: ${support ? 'příznivé' : 'zátěžové'} období',
          facts: 'Průvodce vztahem, časová osa: tranzitující ${pn(p[1])} tvoří ${support ? 'konjunkci nebo trigon' : 'konjunkci, kvadrát nebo opozici'} '
              '${p[2] == 'axis' ? 'k ascendentu nebo descendentu' : 'k natální planetě'} jednoho z vás. Trvá měsíce až roky, '
              'dotýká se jednoho a druhý to prožívá s ním.\n'
              '${pn(p[1])} v období: ${(per['periods'] as Map)[p[1]]}.\n'
              'Čeho se dotýká: ${(per['period_targets'] as Map)[p[2]]}.\n${_planet(p[1])}',
        );
      case 'pair_guide':
        final g = _pairGuide[p[1]]!;
        return (title: g.title, facts: 'Průvodce vztahem v appce (dva uložené profily). ${g.facts}');
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
      case 'election':
        return _election(p);
      case 'horary':
        return _horary(p);
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

  /// Election (plan 10.7): intents with their houses and planets, rule texts, verdict templates.
  static const _intentCz = {
    'relationship': 'svatba, vztah',
    'contract': 'smlouva, podpis, jednání',
    'launch': 'zahájení podnikání, spuštění projektu',
    'money': 'peníze, nákup',
    'move': 'stěhování, nemovitost',
    'travel': 'cesta',
    'study': 'zkouška, studium',
    'application': 'žádost, pohovor',
  };
  static const _verdictCz = {
    'strong': 'okno s vysokým skóre: tradiční pravidla se v něm sbíhají',
    'good': 'dobré okno: víc důvodů pro než proti',
    'weak': 'slabé okno: projde, ale důvodů proti je dost',
    'none': 'v období neprošlo žádné okno; appka ukazuje nejméně špatné s výčtem důvodů proti',
    'health': 'zdravotní záměr (operace, zákrok): appka termín nehledá a odkazuje na slovníček',
  };
  static const _electionFrame =
      'Elekční astrologie: hledání vhodného okamžiku k začátku věci podle tradičních pravidel. '
      'Formulace vždy "podle tradičních pravidel", nikdy záruka ani rada.';

  ({String title, String facts}) _election(List<String> p) {
    switch (p[1]) {
      case 'rule':
        final r = rules[p[2]];
        final about = r?['about'] ?? p[2];
        final kind = switch (r?['kind']) { 'plus' => 'mluví pro', 'minus' => 'mluví proti', _ => 'vylučuje okno' };
        return (title: 'Pravidlo elekce: $about', facts: '$_electionFrame\nPravidlo ($kind): $about\nVysvětli, proč to tradice bere jako dobré nebo špatné.');
      case 'intent':
        final i = ElectionIntent.values.byName(p[2]);
        final planets = i.planets.map((b) => _p(b.name)['name']).join(', ');
        return (
          title: 'Záměr: ${_intentCz[p[2]]}',
          facts: '$_electionFrame\nZáměr: ${_intentCz[p[2]]}. Domy: ${i.houses.join(', ')}. Planety záměru: $planets.\n'
              '${i.houses.map((h) => _house('$h')).join('\n')}\nNa co tradice u takového začátku hledí.'
        );
      default:
        return (title: 'Výsledek hledání: ${p[2]}', facts: '$_electionFrame\nŠablona výsledku: ${_verdictCz[p[2]]}.');
    }
  }

  static const _horaryFrame =
      'Horární astrologie: horoskop okamžiku otázky, verdikt na jednu konkrétní otázku podle pravidel Williama Lillyho '
      '(Christian Astrology, 1647): sedm planet, tradiční vládci, domy Regiomontanus. Formulace vždy "podle tradičních '
      'pravidel vychází", nikdy "stane se".';
  static const _verdictHoraryCz = {
    'yes': 'ano: ukazatelé dojdou k dokonání a nic ho neruší',
    'yes_difficult': 'ano, ale s potížemi: dokonání kvadrátem nebo opozicí bez přijetí',
    'no': 'ne: ukazatelé se před opuštěním znamení nesetkají',
    'past': 'už je to pryč: ukazatelé se od aspektu vzdalují',
    'nothing': 'nic z toho nebude: dokonání zruší zábrana, zmaření, ústup nebo spálení',
    'unclear': 'nelze říct: tazatele i věc zastupuje stejná planeta a Měsíc nic nedokládá',
  };
  static const _timingCz = {
    'days': 'dny', 'weeks': 'týdny', 'months': 'měsíce', 'years': 'roky', 'unknown': 'jednotku tradice neurčuje',
  };

  ({String title, String facts}) _horary(List<String> p) {
    String pn(String id) => _p(id)['name'] as String;
    switch (p[1]) {
      case 'house':
        return (title: '${p[2]}. dům v horární otázce', facts: '$_horaryFrame\n${_house(p[2])}\nCo a koho tento dům v horární otázce zastupuje.');
      case 'significator':
        return (title: '${pn(p[2])} jako ukazatel', facts: '$_horaryFrame\n${_planet(p[2])}\nKoho a co planeta jako ukazatel v horární otázce zastupuje.');
      case 'testimony' || 'consideration':
        final r = horary['${p[1] == 'testimony' ? 'testimonies' : 'considerations'}/${p[2]}'];
        final about = r?['about'] ?? p[2];
        final kind = p[1] == 'consideration'
            ? 'výhrada před výkladem (varování, výklad neblokuje)'
            : (r?['kind'] == 'plus' ? 'svědectví pro' : 'svědectví proti');
        return (
          title: '${p[1] == 'testimony' ? 'Svědectví' : 'Výhrada'}: $about',
          facts: '$_horaryFrame\nPravidlo ($kind): $about\nPramen: ${r?['source'] ?? ''}\nVysvětli, proč to tradice tak čte.',
        );
      case 'verdict':
        return (title: 'Verdikt: ${p[2]}', facts: '$_horaryFrame\nŠablona verdiktu: ${_verdictHoraryCz[p[2]]}.');
      case 'timing':
        return (
          title: 'Čas: ${_timingCz[p[2]]}',
          facts: '$_horaryFrame\nOdhad času: stupně do dokonání se čtou jako ${_timingCz[p[2]]} podle druhu znamení a domu. Tradiční odhad, ne termín.',
        );
      case 'lost':
        return (
          title: 'Ztracená věc: ${_s(p[2])['name']}',
          facts: '$_horaryFrame\n${_sign(p[2])}\nLilly (1647, místa znamení, přelož a přibliž dnešku): ${horary['places/${p[2]}']?['place'] ?? ''}\n'
              'Kde podle Lillyho hledat ztracenou věc, když její ukazatel stojí v tomto znamení: druh místa a směr.',
        );
      case 'lost_house':
        return (
          title: 'Ztracená věc v ${p[2]}. domě',
          facts: '$_horaryFrame\n${_house(p[2])}\nKde podle Lillyho hledat ztracenou věc, když její ukazatel stojí v tomto domě: druh místa a směr.',
        );
    }
    throw ArgumentError(p.join('/'));
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

  /// Chapter intros and notes of the relationship guide (plan R9 5.1).
  static const _pairGuide = {
    'overview': (title: 'Přehled', facts: 'Úvod přehledu: appka ukazuje v pěti oblastech (cit, řeč, láska, energie, respekt), kolik kontaktů mezi horoskopy souzní a kolik se tře. Vysvětli, že to není skóre vztahu ani verdikt, jen mapa, kde jde vztah lehce a kde chce pozornost.'),
    'strengths': (title: 'V čem si vyhovíte', facts: 'Úvod kapitoly o podpůrných kontaktech: co vám jde samo, na co se můžete spolehnout a co si navzájem dáváte.'),
    'cautions': (title: 'Na co si dát pozor', facts: 'Úvod kapitoly o třecích kontaktech: místa, kde se snadno nedorozumíte nebo zraníte. Nejsou to rozsudky; tření je i zdroj růstu, když o něm víte.'),
    'talk': (title: 'Jak spolu mluvit', facts: 'Úvod kapitoly o komunikaci: jak každý z vás mluví a poslouchá a co pomáhá, aby se slova potkala.'),
    'respect': (title: 'Jak se respektovat', facts: 'Úvod kapitoly o respektu: za co chce být každý z vás viděn a uznán a kde snadno přešlapujete.'),
    'needs': (title: 'Co kdo potřebuje', facts: 'Úvod kapitoly o potřebách: co každý z vás od druhého potřebuje a očekává (bezpečí, náklonnost, energie, protějšek) a jak mu to dopřát.'),
    'periods': (title: 'Zátěžová období', facts: 'Úvod kapitoly o čase: pomalé planety procházejí citlivými body horoskopů a tradice taková období čte jako zkoušky. Nejsou to předpovědi, že něco nastane; vedle zátěže appka ukazuje i příznivá období a klidnější okna.'),
    'calm_window': (title: 'Klidnější okno', facts: 'Jedna až dvě věty k oddělovači na časové ose: aspoň tři měsíce, kdy ani jeden z vás neprochází zátěžovým obdobím. Dobrý čas na rozhodnutí a společné plány.'),
    'shared_period': (title: 'Oba najednou', facts: 'Jedna až dvě věty ke štítku: zátěžové období obou z vás se překrývá aspoň měsíc. Každý má méně sil pro toho druhého; pomáhá to vědět.'),
    'no_birth_time': (title: 'Bez času narození', facts: 'Upozornění: u jednoho z vás chybí čas narození, takže chybí osy a domy a znamení Měsíce může být nejisté; průvodce je proto kratší.'),
    'method': (title: 'Co průvodce je a co není', facts: 'Vysvětli metodu: tradiční čtení dvou horoskopů (aspekty mezi nimi, znamení planet, tranzity pomalých planet). Účinek není doložený; srovnání napětí tranzitů se zlomovými událostmi osobností z katalogu appky žádnou souvislost neukázalo. Průvodce nedává verdikt o vztahu a neslibuje, že období nastane. Rady jsou návrhy k rozhovoru, ne pokyny.'),
  };

  String _qualityName(String q) =>
      {'conjunction': 'konjunkce', 'harmonious': 'harmonický aspekt (sextil, trigon)', 'tense': 'napěťový aspekt (kvadrát, opozice)'}[q] ?? q;

  String _elementCz(String e) => {'fire': 'oheň', 'earth': 'země', 'air': 'vzduch', 'water': 'voda'}[e] ?? e;


  static const _singleVoice =
      '- 2. osoba, tykání, přítomný čas. Bez rodových tvarů: žádné "jsi citlivý/citlivá",\n'
      '  "byl jsi", "mohla bys". Použij podstatná jména nebo slovesa ("máš citlivou povahu").\n';

  static const _needVoice =
      '- Text čte ten druhý. O člověku s postavením piš ve 3. osobě bez rodu: "kdo má Měsíc v Raku,\n'
      '  potřebuje…", "člověk s Venuší ve Váze". Žádné on, ona, jeho, její; místo toho "ten druhý",\n'
      '  "blízký člověk". Jména nepiš, appka je dá do nadpisu.\n';

  static String _adviceRule(String family) {
    final (lo, hi) = family == 'pair_period' ? (40, 80) : (30, 70);
    return '- "advice": $lo–$hi slov, vrstva "Co s tím": konkrétní jednání ve vztahu (jak to říct, na čem se\n'
        '  domluvit, kdy si dát pauzu, co nedělat). ${family == 'pair_need' ? 'Neosobně: "Pomáhá…", "Funguje…", "Nefunguje…".' : 'Oslovuj oba ("domluvte si", "zkuste").'}\n'
        '  ${family == 'pair_period' ? 'Co pomáhá tomu, kdo období prožívá, a co druhému. U Jupitera: jak období využít.\n  ' : ''}'
        'Zakázáno: rady k léčbě, lékům, penězům a právu; verdikt o vztahu (zůstat, rozejít se); cokoli,\n'
        '  co vede k snášení násilí nebo ponižování. Žádná romantika ani intimita.\n';
  }

  /// Prompt for the `advice` layer of an existing text (`generate --layer advice`).
  String buildAdvice(ContentEntry e) {
    final family = familyOf(e.key);
    return """
Doplň k hotovému českému textu astrologického výkladu vztahu vrstvu "Co s tím" (pole "advice").

POSTAVENÍ: ${e.title}
TEXT: ${e.text}
STINNÁ STRÁNKA: ${e.shadow}

PRAVIDLA:
- Oslovuj oba: 2. osoba množného čísla, přítomný čas. "Jeden z vás", "druhý" místo jmen.
  Bez rodových tvarů ("byli jste" ne). Text platí pro jakýkoli vztah: partneři, rodič a dítě,
  sourozenci, přátelé, kolegové.
${_adviceRule(family)}- Navaž na text a stín; neopakuj je. Krátké konkrétní věty.

Odpověz jen JSON objektem:
{"key": "${e.key}", "advice": ""}
""";
  }

  String build(String key) {
    final d = describe(key);
    final len = lengthRange(key);
    final family = familyOf(key);
    final noShadow = isShadowExempt(key);
    final traitList = traits.map((t) => '${t.id} (${t.name})').join(', ');
    final pair = relationshipFamilies.contains(family);
    final withPartner = allowsPartner(key);
    final withAdvice = adviceFamilies.contains(family);
    final textRule = family == 'pair_need'
        ? '- "text": ${len.min}–${len.max} slov: co člověk s tímto postavením potřebuje a očekává od blízkého člověka.\n'
            '  Text platí pro jakýkoli vztah. Žádná romantika ani intimita v "text", "shadow", "advice", "hard".'
        : family == 'pair_elements'
        ? '- "text": ${len.min}–${len.max} slov: jak se ty dva způsoby potkávají, v čem se doplňují.\n'
            '  Text platí pro jakýkoli vztah. Žádná romantika ani intimita v "text", "shadow", "advice", "hard".'
        : family == 'pair_period'
        ? '- "text": ${len.min}–${len.max} slov: čím prochází ten, koho se období týká, a co to dělá mezi vámi.\n'
            '  Formulace tradice ("tradice čte toto období jako…"), nikdy "přijde krize" ani jistota. Platí pro jakýkoli vztah.'
        : family == 'pair_guide'
        ? '- "text": ${len.min}–${len.max} slov: krátký úvod nebo poznámka pro appku, věcně a vlídně.'
        : pair
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
            : family == 'election'
                ? '- "text": ${len.min}–${len.max} slov: co o tom říká tradice elekcí a proč; "podle tradičních pravidel",\n'
                    '  nikdy záruka, žádná rada ke zdraví, penězům ani právu.'
            : family == 'horary'
                ? '- "text": ${len.min}–${len.max} slov: co o tom říká horární tradice (William Lilly, 1647) a proč;\n'
                    '  "podle tradičních pravidel vychází", nikdy "stane se"; žádná rada ke zdraví, penězům ani právu.'
            : family == 'journal'
                ? '- "text": ${len.min}–${len.max} slov: věcné vysvětlení výsledku pro laika, bez astrologického výkladu povahy.'
                : '- "text": ${len.min}–${len.max} slov: povaha, nadání, projevy.';
    return '''
Napiš český text astrologického výkladu pro mobilní appku.

POSTAVENÍ: ${d.title}
VÝZNAMY (ručně psaná tabulka archetypů, rozviň je vlastními slovy):
${d.facts}

PRAVIDLA:
${family == 'pair_need' ? _needVoice : pair ? '- Oslovuj oba: 2. osoba množného čísla ("mezi vámi", "máte"), přítomný čas.\n  "Jeden z vás", "druhý" místo jmen. Bez rodových tvarů ("byli jste" ne).\n' : ''}${pair ? '' : _singleVoice}- Krátké konkrétní věty, žádné fráze o hvězdách, žádné rady k léčbě, penězům ani právu.
- První věta textu i stínu patří jen téhle kombinaci. Žádná obecná věta o znamení
  nebo planetě ("Stálost se snadno mění v…"), kterou by šlo dát i jiné planetě.
- Žádné "sám/sama", "rád/ráda" o čtenáři; "sám o sobě" o věci je v pořádku.
- Úplný tradiční výklad. Nic nevynechávej ani nezměkčuj, včetně smrti a nemocí.
  Těžká témata věcně a s uvozením "tradice tu mluví o…", nikdy jako jistota.
$textRule
${withPartner && !partnerFamilies.contains(family) ? '- "partner": 30–80 slov: přitažlivost a intimita, jen pro milostný pár. Appka ho ukáže pouze\n  u typu vztahu partner, u rodiče a dítěte nikdy.\n' : ''}${withAdvice ? _adviceRule(family) : ''}${noShadow ? '- "shadow": prázdný řetězec.' : '- "shadow": 40–100 slov: slabiny a odvrácená strana téhož.'}
- "hard": seznam pasáží o těžkých tématech, jen kde tradice něco říká; každá má
  "topics" z výčtu ${hardTopics.join(', ')} a "text" 20–80 slov.
- "keywords": 3–5 hesel malými písmeny. "themes": z výčtu ${themeIds.join(', ')}.
- "traits": {"text": [...], "shadow": [...]} — 2–5 id na vrstvu, jen z tohoto slovníku:
  $traitList

Odpověz jen JSON objektem:
{"key": "$key", "title": "${d.title}", "keywords": [], "themes": [], "text": "", "shadow": "", "hard": [], "traits": {"text": [], "shadow": []}${withPartner ? ', "partner": ""' : ''}${withAdvice ? ', "advice": ""' : ''}}
''';
  }
}
