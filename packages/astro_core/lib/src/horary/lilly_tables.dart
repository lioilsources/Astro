/// Tables of William Lilly, *Christian Astrology* (London 1647), copied from
/// the 1647 edition (Wellcome copy on archive.org, cross-checked with the
/// EEBO/ProQuest scan). Page numbers are the printed pages of 1647; every
/// table is cited again in docs/horary.md. Owner decision 21: Lilly's
/// tradition — seven planets, Ptolemaic terms, day and night triplicities.
library;

import '../angles.dart';
import '../model.dart';

/// One term: [ruler] rules from the previous term's end up to [end] (degrees
/// within the sign).
typedef Term = ({Body ruler, double end});

/// "A Table of the Essentiall Dignities of the Planets according to Ptolomy",
/// CA p. 104 (Book I, ch. XVIII), column "The Termes of the Planets".
/// p. 105: "the first six degrees of ♈ are the Termes of ♃; from six to
/// fourteen, the Termes of ♀, &c."
const Map<Sign, List<Term>> lillyTerms = {
  Sign.aries: [(ruler: Body.jupiter, end: 6), (ruler: Body.venus, end: 14), (ruler: Body.mercury, end: 21), (ruler: Body.mars, end: 26), (ruler: Body.saturn, end: 30)],
  Sign.taurus: [(ruler: Body.venus, end: 8), (ruler: Body.mercury, end: 15), (ruler: Body.jupiter, end: 22), (ruler: Body.saturn, end: 26), (ruler: Body.mars, end: 30)],
  Sign.gemini: [(ruler: Body.mercury, end: 7), (ruler: Body.jupiter, end: 14), (ruler: Body.venus, end: 21), (ruler: Body.saturn, end: 25), (ruler: Body.mars, end: 30)],
  Sign.cancer: [(ruler: Body.mars, end: 6), (ruler: Body.jupiter, end: 13), (ruler: Body.mercury, end: 20), (ruler: Body.venus, end: 27), (ruler: Body.saturn, end: 30)],
  Sign.leo: [(ruler: Body.saturn, end: 6), (ruler: Body.mercury, end: 13), (ruler: Body.venus, end: 19), (ruler: Body.jupiter, end: 25), (ruler: Body.mars, end: 30)],
  Sign.virgo: [(ruler: Body.mercury, end: 7), (ruler: Body.venus, end: 13), (ruler: Body.jupiter, end: 18), (ruler: Body.saturn, end: 24), (ruler: Body.mars, end: 30)],
  Sign.libra: [(ruler: Body.saturn, end: 6), (ruler: Body.venus, end: 11), (ruler: Body.jupiter, end: 19), (ruler: Body.mercury, end: 24), (ruler: Body.mars, end: 30)],
  Sign.scorpio: [(ruler: Body.mars, end: 6), (ruler: Body.jupiter, end: 14), (ruler: Body.venus, end: 21), (ruler: Body.mercury, end: 27), (ruler: Body.saturn, end: 30)],
  Sign.sagittarius: [(ruler: Body.jupiter, end: 8), (ruler: Body.venus, end: 14), (ruler: Body.mercury, end: 19), (ruler: Body.saturn, end: 25), (ruler: Body.mars, end: 30)],
  Sign.capricorn: [(ruler: Body.venus, end: 6), (ruler: Body.mercury, end: 12), (ruler: Body.jupiter, end: 19), (ruler: Body.mars, end: 25), (ruler: Body.saturn, end: 30)],
  Sign.aquarius: [(ruler: Body.saturn, end: 6), (ruler: Body.mercury, end: 12), (ruler: Body.venus, end: 20), (ruler: Body.jupiter, end: 25), (ruler: Body.mars, end: 30)],
  Sign.pisces: [(ruler: Body.venus, end: 8), (ruler: Body.jupiter, end: 14), (ruler: Body.mercury, end: 20), (ruler: Body.mars, end: 26), (ruler: Body.saturn, end: 30)],
};

/// Same table, column "The Faces of the Planets": rulers of 0–10°, 10–20°, 20–30°.
const Map<Sign, List<Body>> lillyFaces = {
  Sign.aries: [Body.mars, Body.sun, Body.venus],
  Sign.taurus: [Body.mercury, Body.moon, Body.saturn],
  Sign.gemini: [Body.jupiter, Body.mars, Body.sun],
  Sign.cancer: [Body.venus, Body.mercury, Body.moon],
  Sign.leo: [Body.saturn, Body.jupiter, Body.mars],
  Sign.virgo: [Body.sun, Body.venus, Body.mercury],
  Sign.libra: [Body.moon, Body.saturn, Body.jupiter],
  Sign.scorpio: [Body.mars, Body.sun, Body.venus],
  Sign.sagittarius: [Body.mercury, Body.moon, Body.saturn],
  Sign.capricorn: [Body.jupiter, Body.mars, Body.sun],
  Sign.aquarius: [Body.venus, Body.mercury, Body.moon],
  Sign.pisces: [Body.saturn, Body.jupiter, Body.mars],
};

/// Same table, column "Triplicity of the Planets", day and night. p. 105:
/// "Over against ♋ ♏ ♓ you find ♂ ♂ who, according to Ptolomy and Naibod,
/// ruleth onely that Triplicity both day and night."
const Map<Element, ({Body day, Body night})> lillyTriplicity = {
  Element.fire: (day: Body.sun, night: Body.jupiter),
  Element.earth: (day: Body.venus, night: Body.moon),
  Element.air: (day: Body.saturn, night: Body.mercury),
  Element.water: (day: Body.mars, night: Body.mars),
};

Body triplicityRuler(Sign s, {required bool isDay}) {
  final t = lillyTriplicity[s.element]!;
  return isDay ? t.day : t.night;
}

/// Ruler of the term containing ecliptic longitude [lon].
Body termRuler(double lon) {
  final s = Sign.ofLongitude(lon);
  final d = norm360(lon) % 30;
  for (final t in lillyTerms[s]!) {
    if (d < t.end) return t.ruler;
  }
  return lillyTerms[s]!.last.ruler;
}

/// Ruler of the face (decanate) containing [lon].
Body faceRuler(double lon) {
  final d = norm360(lon) % 30;
  return lillyFaces[Sign.ofLongitude(lon)]![(d ~/ 10).clamp(0, 2)];
}

/// "A ready Table whereby to examine the Fortitudes and Debilities of the
/// Planets", CA p. 115. Debilities are negative.
const Map<String, int> lillyFortitudes = {
  // Essential dignities.
  'domicile': 5, // "in his own house, or in mutual reception with another Planet by house"
  'mutual_reception_house': 5,
  'exaltation': 4, // "In his exaltation, or reception by exaltation"
  'mutual_reception_exaltation': 4,
  'triplicity': 3,
  'term': 2,
  'face': 1,
  // Essential debilities.
  'detriment': -5,
  'fall': -4,
  'peregrine': -5,
  // Accidental fortitudes.
  'house_1_10': 5, // "In the Mid-heaven or Ascendant"
  'house_4_7_11': 4,
  'house_2_5': 3,
  'house_9': 2,
  'house_3': 1,
  'direct': 4, // "the ☉ and ☽ are alwayes so, as to them this is voyd"
  'swift': 2,
  'superior_oriental': 2, // "♄ ♃ ♂ when Orientall"
  'inferior_occidental': 2, // "☿ and ♀ when Occidentall"
  'moon_increasing': 2, // "The ☽ encreasing, or when she is Occidentall"
  'free_from_combustion': 5, // "Free from Combustion and ☉ Beams"
  'cazimi': 5,
  'partile_conj_benefic': 5, // "In partill ☌ with ♃ and ♀"
  'partile_north_node': 4,
  'partile_trine_benefic': 4,
  'partile_sextile_benefic': 3,
  'regulus': 6, // "In ☌ with Cor Leonis, in 24. degr. ♌"
  'spica': 5, // "Or in ☌ with Spica ♍, in 18. ♎"
  // Accidental debilities.
  'house_12': -5,
  'house_6_8': -2,
  'retrograde': -5,
  'slow': -2,
  'superior_occidental': -2,
  'inferior_oriental': -2,
  'moon_decreasing': -2,
  'combust': -5,
  'under_beams': -4,
  'partile_conj_malefic': -5, // "Partill ☌ with ♄ or ♂"
  'partile_south_node': -4,
  'besieged': -5, // "Besieged of ♄ and ♂"
  'partile_opposition_malefic': -4,
  'partile_square_malefic': -3,
  'algol': -5, // "In ☌ with Caput Algol in 20. ♉, or within five degrees"
};

/// Fixed stars of the fortitude table by catalog id (stars.dart), with the
/// orb in degrees. Lilly gives five degrees only for Algol; for Regulus and
/// Spica the app uses the fixed-star orb of the app, 1° (owner decision 18;
/// unresolved in the source, docs/horary.md).
const Map<String, ({String id, double orb})> lillyStars = {
  'regulus': (id: 'regulus', orb: 1),
  'spica': (id: 'spica', orb: 1),
  'algol': (id: 'algol', orb: 5),
};

/// Mean daily motion, degrees (Book I, chapters VIII–XIV): ♄ "two minutes and
/// one second" p. 57; ♃ "4 min. 59 seconds" p. 61; ♂ "31 … 27 min." p. 65;
/// ☉ "59 8" p. 69; ♀ "59. min. and 8. seconds" pp. 72–73; ☿ "59. min. and 8.
/// seconds" p. 76; ☽ "13 degr. 10 min. and 36 seconds" p. 80. Faster than the
/// mean = "swift in motion" of the fortitude table.
const Map<Body, double> lillyMeanMotion = {
  Body.saturn: (2 + 1 / 60) / 60,
  Body.jupiter: (4 + 59 / 60) / 60,
  Body.mars: (31 + 27 / 60) / 60,
  Body.sun: (59 + 8 / 60) / 60,
  Body.venus: (59 + 8 / 60) / 60,
  Body.mercury: (59 + 8 / 60) / 60,
  Body.moon: 13 + 10 / 60 + 36 / 3600,
};

/// Orbs, CA p. 107, Lilly's own column ("as I have found by the best Authors
/// and my owne Experience"): ♄ 10°, ♃ 12°, ♂ 7°30′, ☉ 17°, ♀ 8°, ☿ 7°, ☽ 12°30′.
/// p. 110: "every Planet that applies is allowed halfe his owne orbs and halfe
/// the orbs of that Planet from whom he seperates".
const Map<Body, double> lillyOrbs = {
  Body.saturn: 10,
  Body.jupiter: 12,
  Body.mars: 7.5,
  Body.sun: 17,
  Body.venus: 8,
  Body.mercury: 7,
  Body.moon: 12.5,
};

/// Half the orb (moiety); two planets are in aspect within the sum of their moieties.
double lillyMoiety(Body b) => lillyOrbs[b]! / 2;

/// CA p. 113: cazimi "within 17. min. forward or backward"; combust "in the
/// same Signe … not distant from the ☉ eight degrees and thirty minutes";
/// under the beams "untill he is fully elongated … 17. degr.".
const lillyCazimi = 17 / 60;
const lillyCombust = 8.5;
const lillyUnderBeams = 17.0;

/// Planets that rule a triplicity together (by day or by night), CA p. 104.
Set<Body> _triplicityMates(Body b) => {
      for (final t in lillyTriplicity.values)
        if (t.day == b || t.night == b) ...{t.day, t.night},
    };

/// Radicality, CA p. 121: "the Lord of the hour … and the Lord of the
/// Ascendant … are of one Triplicity, or be one, or of the same nature".
/// "Of one triplicity" is read as both ruling the same triplicity; "of the
/// same nature" is not implemented (docs/horary.md, unresolved).
bool hourAgreesWithAsc(Body hourRuler, Body ascRuler) => hourRuler == ascRuler || _triplicityMates(hourRuler).contains(ascRuler);
