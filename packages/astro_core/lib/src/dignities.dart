import 'model.dart';

enum Dignity { domicile, exaltation, detriment, fall, peregrine }

/// Rulers. Modern rulers sit next to traditional ones (Mars and Pluto in Scorpio…).
const Map<Body, List<Sign>> domicile = {
  Body.sun: [Sign.leo],
  Body.moon: [Sign.cancer],
  Body.mercury: [Sign.gemini, Sign.virgo],
  Body.venus: [Sign.taurus, Sign.libra],
  Body.mars: [Sign.aries, Sign.scorpio],
  Body.jupiter: [Sign.sagittarius, Sign.pisces],
  Body.saturn: [Sign.capricorn, Sign.aquarius],
  Body.uranus: [Sign.aquarius],
  Body.neptune: [Sign.pisces],
  Body.pluto: [Sign.scorpio],
};

/// Exaltations. Classical for the seven; the modern three are disputed,
/// the chosen ones are documented in docs/scoring.md.
const Map<Body, Sign> exaltation = {
  Body.sun: Sign.aries,
  Body.moon: Sign.taurus,
  Body.mercury: Sign.virgo,
  Body.venus: Sign.pisces,
  Body.mars: Sign.capricorn,
  Body.jupiter: Sign.cancer,
  Body.saturn: Sign.libra,
  Body.uranus: Sign.scorpio,
  Body.neptune: Sign.cancer,
  Body.pluto: Sign.leo,
};

/// Traditional (pre-1781) ruler of a sign — used by horary and profections.
Body traditionalRuler(Sign s) => switch (s) {
      Sign.aries || Sign.scorpio => Body.mars,
      Sign.taurus || Sign.libra => Body.venus,
      Sign.gemini || Sign.virgo => Body.mercury,
      Sign.cancer => Body.moon,
      Sign.leo => Body.sun,
      Sign.sagittarius || Sign.pisces => Body.jupiter,
      Sign.capricorn || Sign.aquarius => Body.saturn,
    };

/// Modern ruler of a sign.
Body modernRuler(Sign s) => switch (s) {
      Sign.scorpio => Body.pluto,
      Sign.aquarius => Body.uranus,
      Sign.pisces => Body.neptune,
      _ => traditionalRuler(s),
    };

Dignity dignityOf(Body b, Sign s) {
  final dom = domicile[b];
  if (dom == null) return Dignity.peregrine;
  if (dom.contains(s)) return Dignity.domicile;
  if (exaltation[b] == s) return Dignity.exaltation;
  if (dom.any((d) => d.opposite == s)) return Dignity.detriment;
  if (exaltation[b]?.opposite == s) return Dignity.fall;
  return Dignity.peregrine;
}

/// Planet condition score (docs/scoring.md). Negative → shadow layer goes first.
int planetScore({required Body body, required Sign sign, int? house, required bool retrograde, int tenseAspects = 0, int harmoniousAspects = 0}) {
  var s = switch (dignityOf(body, sign)) {
    Dignity.domicile => 5,
    Dignity.exaltation => 4,
    Dignity.detriment => -5,
    Dignity.fall => -4,
    Dignity.peregrine => 0,
  };
  if (house != null) {
    if (const {1, 4, 7, 10}.contains(house)) s += 2;
    if (const {6, 8, 12}.contains(house)) s -= 1;
  }
  if (retrograde && body != Body.sun && body != Body.moon) s -= 1;
  s += harmoniousAspects - tenseAspects;
  return s;
}
