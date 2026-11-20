import '../election.dart';
import '../model.dart';
import '../patterns.dart';
import '../stars.dart';

/// Content ids of planets: the ten planets + the lunar node (mean or true alike).
const planetIds = ['sun', 'moon', 'mercury', 'venus', 'mars', 'jupiter', 'saturn', 'uranus', 'neptune', 'pluto'];
const planetAndNodeIds = [...planetIds, 'node'];
const majorAspectIds = ['conjunction', 'sextile', 'square', 'trine', 'opposition'];
const qualityIds = ['conjunction', 'harmonious', 'tense'];
final signIds = Sign.values.map((s) => s.name).toList();
final elementIds = Element.values.map((e) => e.name).toList();
const houseNumbers = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12];

const transitModifierIds = [
  'approaching',
  'exact',
  'separating',
  'pass_1',
  'pass_2',
  'pass_3',
  'station',
  'concurrence',
];

const glossaryIds = [
  'ascendant', 'descendant', 'mc', 'ic', 'house', 'cusp', 'house_system', 'placidus', 'porphyry',
  'koch', 'regiomontanus', 'campanus', 'equal', 'whole_sign', 'meridian', 'morinus',
  'aspect', 'orb', 'applying', 'conjunction', 'sextile', 'square', 'trine', 'opposition',
  'ruler', 'domicile', 'exaltation', 'detriment', 'fall', 'retrograde', 'station',
  'node', 'transit', 'natal_chart', 'element', 'modality', 'sign', 'planet', 'twins', 'shadow',
  'fixed_star', 'precession', 'royal_stars',
  // R7 (plan 10.7, owner decision 19)
  'election', 'via_combusta', 'reception', 'medical_election',
];

/// R2 (plan 10.2): Moon and planetary hours.
const moonPhaseIds = ['new', 'crescent', 'first_quarter', 'gibbous', 'full', 'disseminating', 'last_quarter', 'balsamic'];
const traditionalPlanetIds = ['sun', 'moon', 'mercury', 'venus', 'mars', 'jupiter', 'saturn'];
const lunationIds = ['new', 'full'];
const eclipseIds = ['solar', 'lunar'];

/// Aspect patterns and balances (plan 10.1).
final modalityIds = Modality.values.map((m) => m.name).toList();
final hemisphereIds = Hemisphere.values.map((h) => h.name).toList();
final patternKeys = [
  for (final e in elementIds) 'pattern/grand_trine/$e',
  for (final m in modalityIds) 'pattern/t_square/$m',
  for (final p in planetIds) 'pattern/t_square_apex/$p',
  for (final m in modalityIds) 'pattern/grand_cross/$m',
  for (final p in planetIds) 'pattern/yod_apex/$p',
  for (final e in elementIds) 'pattern/kite/$e',
  'pattern/cradle',
  'pattern/mystic_rectangle',
  for (final m in modalityIds) ...['pattern/modality/$m/excess', 'pattern/modality/$m/lack'],
  for (final h in hemisphereIds) 'pattern/hemisphere/$h',
  for (final p in planetIds) 'pattern/unaspected/$p',
];

/// Election rules (plan 10.7): ids of `content/rules/election.json`, which a
/// tools/content test keeps in sync with this list.
const electionRuleIds = [
  'moon_void',
  'moon_waxing', 'moon_next_venus', 'moon_next_jupiter', 'venus_angle', 'jupiter_angle', 'asc_ruler_dignified',
  'hour_of_intent', 'intent_planet_dignified', 'benefic_in_intent_house', 'personal_moon_harmonious', 'personal_calm_day',
  'moon_next_mars_hard', 'moon_next_saturn_hard', 'mars_angle', 'saturn_angle', 'intent_planet_retrograde',
  'intent_planet_fall', 'intent_planet_detriment', 'asc_ruler_bad_house', 'asc_ruler_retrograde', 'eclipse',
  'via_combusta', 'malefic_in_intent_house', 'personal_moon_tense', 'personal_tension_high',
];
final electionKeys = [
  for (final r in electionRuleIds) 'election/rule/$r',
  for (final i in ElectionIntent.values) 'election/intent/${i.id}',
  for (final v in electionVerdictIds) 'election/verdict/$v',
];

/// Content id of a body (both nodes share the `node` texts).
String contentIdOf(Body b) => b.isNode ? 'node' : b.name;

/// Every key of a family, in a stable order. Families are also the file names
/// in `content/cs/<family>.json`.
Map<String, List<String>> allKeysByFamily() {
  final pairs = <String>[];
  for (var i = 0; i < planetIds.length; i++) {
    for (var j = i + 1; j < planetIds.length; j++) {
      for (final a in majorAspectIds) {
        pairs.add('aspect/${planetIds[i]}/${planetIds[j]}/$a');
      }
    }
  }
  return {
    'planet_in_sign': [for (final p in planetAndNodeIds) for (final s in signIds) 'planet_in_sign/$p/$s'],
    'planet_in_house': [for (final p in planetAndNodeIds) for (final h in houseNumbers) 'planet_in_house/$p/$h'],
    'aspect': pairs,
    'aspect_point': [
      for (final pt in ['asc', 'mc', 'node'])
        for (final p in planetIds)
          for (final q in qualityIds) 'aspect_point/$pt/$p/$q'
    ],
    'sign_on_cusp': [for (final h in houseNumbers) for (final s in signIds) 'sign_on_cusp/$h/$s'],
    'transit': [
      for (final t in planetIds)
        for (final n in planetIds)
          for (final a in majorAspectIds) 'transit/$t/$n/$a'
    ],
    'transit_point': [
      for (final t in planetIds)
        for (final pt in ['asc', 'mc'])
          for (final q in qualityIds) 'transit_point/$t/$pt/$q'
    ],
    'transit_in_house': [for (final p in planetIds) for (final h in houseNumbers) 'transit_in_house/$p/$h'],
    'transit_modifier': [for (final m in transitModifierIds) 'transit_modifier/$m'],
    'house_area': [for (final h in houseNumbers) 'house_area/$h'],
    'emphasis': [
      for (final s in signIds) 'emphasis/sign/$s',
      for (final h in houseNumbers) 'emphasis/house/$h',
      for (final e in elementIds) 'emphasis/element_dominant/$e',
      for (final e in elementIds) 'emphasis/element_missing/$e',
    ],
    'pattern': patternKeys,
    'glossary': [for (final g in glossaryIds) 'glossary/$g'],
    'planetary_hour': [for (final p in traditionalPlanetIds) 'planetary_hour/$p'],
    'planetary_day': [for (final p in traditionalPlanetIds) 'planetary_day/$p'],
    'moon_phase': [for (final f in moonPhaseIds) 'moon_phase/$f'],
    'natal_moon_phase': [for (final f in moonPhaseIds) 'natal_moon_phase/$f'],
    'moon_today': [for (final s in signIds) 'moon_today/$s'],
    'lunation_in_house': [for (final k in lunationIds) for (final h in houseNumbers) 'lunation_in_house/$k/$h'],
    'void_of_course': ['void_of_course'],
    'eclipse': [for (final e in eclipseIds) 'eclipse/$e'],
    'star': [for (final s in starIds) 'star/$s'],
    'star_target': [for (final t in starTargetIds) 'star_target/$t'],
    'election': electionKeys,
  };
}

String familyOf(String key) => key.split('/').first;

/// Word-count range (base layer) per family; Sun, Moon and house 1/10 cusps get the long range.
({int min, int max}) lengthRange(String key) {
  final parts = key.split('/');
  switch (parts.first) {
    case 'planet_in_sign':
      return (parts[1] == 'sun' || parts[1] == 'moon') ? (min: 180, max: 300) : (min: 110, max: 250);
    case 'planet_in_house':
    case 'aspect':
      return (min: 70, max: 160);
    case 'aspect_point':
      return (min: 50, max: 110);
    case 'sign_on_cusp':
      return (parts[1] == '1' || parts[1] == '10') ? (min: 120, max: 220) : (min: 35, max: 110);
    case 'transit':
    case 'transit_point':
    case 'transit_in_house':
      return (min: 35, max: 90);
    case 'transit_modifier':
      return (min: 10, max: 35);
    case 'house_area':
      return (min: 10, max: 30);
    case 'emphasis':
    case 'pattern':
      return (min: 50, max: 110);
    case 'glossary':
      return (min: 25, max: 130);
    case 'planetary_hour':
    case 'planetary_day':
    case 'moon_phase':
    case 'moon_today':
    case 'lunation_in_house':
    case 'void_of_course':
      return (min: 35, max: 90);
    case 'natal_moon_phase':
      return (min: 110, max: 200);
    case 'eclipse':
      return (min: 50, max: 110);
    case 'star':
      // Most of a star text lives in shadow and hard (plan 10.6): no minimum for the base.
      return (min: 0, max: 250);
    case 'star_target':
      return (min: 8, max: 40);
    case 'election':
      return switch (parts[1]) {
        'rule' => (min: 25, max: 70),
        'intent' => (min: 30, max: 80),
        _ => (min: 15, max: 50),
      };
  }
  return (min: 1, max: 10000);
}

/// Keys where tradition does speak about hard topics → empty `hard` is a warning.
bool expectsHard(String key) {
  final p = key.split('/');
  const malefics = {'mars', 'saturn', 'neptune', 'pluto'};
  switch (p.first) {
    case 'planet_in_house':
      return p[2] == '8' || p[2] == '12';
    case 'aspect':
      return (p[3] == 'square' || p[3] == 'opposition' || p[3] == 'conjunction') &&
          (malefics.contains(p[1]) || malefics.contains(p[2]));
    case 'transit':
      return (p[3] == 'square' || p[3] == 'opposition' || p[3] == 'conjunction') && malefics.contains(p[1]);
    case 'transit_in_house':
      return p[2] == '8' || p[2] == '12';
    case 'lunation_in_house':
      return p[2] == '8' || p[2] == '12';
    case 'eclipse':
    case 'star':
      return true;
  }
  return false;
}
