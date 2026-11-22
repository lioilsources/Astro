import '../aspects.dart';
import '../chart.dart';
import '../model.dart';
import '../pair_timeline.dart';
import '../synastry.dart';
import 'factors.dart';

/// Relationship guide (plan R9, 4.1): the facts of a pair arranged in chapters.
/// Pure facts and content keys; the app renders the texts.

enum PairTone { supportive, straining }

/// Areas of the overview: feeling (Moon), talk (Mercury), love (Venus),
/// energy (Mars), respect (Sun, Saturn).
enum PairArea { feeling, talk, love, energy, respect }

const _areaBodies = {
  Body.moon: PairArea.feeling,
  Body.mercury: PairArea.talk,
  Body.venus: PairArea.love,
  Body.mars: PairArea.energy,
  Body.sun: PairArea.respect,
  Body.saturn: PairArea.respect,
};

/// Tone of an inter-chart aspect (docs/scoring.md): harmonious supports, tense strains;
/// a conjunction strains with Saturn, Uranus, Neptune or Pluto, or with Mars unless
/// the other planet is Venus or Jupiter.
PairTone toneOf(Aspect a) {
  switch (a.type.quality) {
    case AspectQuality.harmonious:
      return PairTone.supportive;
    case AspectQuality.tense:
      return PairTone.straining;
    case AspectQuality.conjunction:
      final bodies = [a.a.body, a.b.body].whereType<Body>().toList();
      const heavy = {Body.saturn, Body.uranus, Body.neptune, Body.pluto};
      if (bodies.any(heavy.contains)) return PairTone.straining;
      if (bodies.contains(Body.mars)) {
        final other = bodies.length == 2 ? (bodies[0] == Body.mars ? bodies[1] : bodies[0]) : null;
        if (other != Body.venus && other != Body.jupiter) return PairTone.straining;
      }
      return PairTone.supportive;
  }
}

/// Areas an aspect counts into: one per planet that has an area.
Set<PairArea> areasOf(Aspect a) => {
      for (final b in [a.a.body, a.b.body])
        if (b != null && _areaBodies[b] != null) _areaBodies[b]!,
    };

/// Points of a person the guide describes as needs (`pair_need/{point}/…`).
enum NeedPoint {
  sun(Body.sun),
  moon(Body.moon),
  mercury(Body.mercury),
  venus(Body.venus),
  mars(Body.mars),
  dsc(null);

  final Body? body;
  const NeedPoint(this.body);
}

/// Planets compared by the element of their sign (`pair_elements/{planet}/…`).
const pairElementBodies = [Body.sun, Body.moon, Body.mercury, Body.venus, Body.mars];

/// Largest Moon motion in 12 hours: without a birth time a noon Moon closer than
/// this to a sign boundary may belong to the neighbouring sign.
const moonUncertainDeg = 7.7;

/// True when the Moon sign of [c] is not certain (no birth time, Moon near a cusp).
bool moonSignUncertain(Chart c) {
  if (c.timeKnown) return false;
  final m = c.positions[Body.moon];
  if (m == null) return true;
  final d = m.degreeInSign;
  return d < moonUncertainDeg || d > 30 - moonUncertainDeg;
}

class PersonNeed {
  final bool ofFirst;
  final NeedPoint point;
  final Sign sign;
  const PersonNeed(this.ofFirst, this.point, this.sign);
  String get key => pairNeedKey(point, sign);
  double get weight => point.body == null ? 0.8 : bodyWeight(point.body!);
}

class ElementPair {
  final Body body;
  final Element first;
  final Element second;
  const ElementPair(this.body, this.first, this.second);
  String get key => pairElementsKey(body, first, second);
  double get weight => bodyWeight(body);
}

/// Links to aspects at the end of the chapters talk, respect and needs.
const maxGuideLinks = 5;

enum GuideChapterId { overview, strengths, cautions, talk, respect, needs, periods }

String pairNeedKey(NeedPoint p, Sign s) => 'pair_need/${p.name}/${s.name}';

/// Element pairs are unordered: the lower element index goes first.
String pairElementsKey(Body b, Element x, Element y) {
  final (a, c) = x.index <= y.index ? (x, y) : (y, x);
  return 'pair_elements/${b.name}/${a.name}/${c.name}';
}

String pairGuideKey(GuideChapterId id) => 'pair_guide/${id.name}';

/// Text of a period: `pair_period/{planet}/{target}` or `pair_period/cycle/{id}`.
String pairPeriodKey(PairPeriod p) {
  if (p.cycle != null) return 'pair_period/cycle/${p.cycle}';
  final t = p.series.target;
  return 'pair_period/${p.series.transiting.name}/${t.isAngle ? 'axis' : t.body!.name}';
}

/// The existing transit text of the configuration behind a period.
String pairPeriodTransitKey(PairPeriod p) {
  final s = p.series;
  return s.target.isAngle
      ? 'transit_point/${s.transiting.name}/${s.target.angle!.name}/${qualityId(s.type)}'
      : 'transit/${s.transiting.name}/${s.target.body!.name}/${s.type.name}';
}

/// One block of a chapter. Exactly one of [facts], [need], [elements] is set.
class GuideBlock {
  final String key;

  /// Inter-chart facts that lead to [key] (aspects to planets or axes).
  final List<Factor> facts;
  final PersonNeed? need;
  final ElementPair? elements;

  /// Only a link to a text shown in full in another chapter.
  final bool linkOnly;

  /// [need] holds for both people (same sign): the text is shown once for both.
  final bool bothPeople;
  const GuideBlock(this.key, {this.facts = const [], this.need, this.elements, this.linkOnly = false, this.bothPeople = false});

  double get weight => facts.isNotEmpty
      ? facts.map((f) => f.weight).reduce((a, b) => a > b ? a : b)
      : (need?.weight ?? elements?.weight ?? 0);
}

class GuideChapter {
  final GuideChapterId id;
  final List<GuideBlock> blocks;
  const GuideChapter(this.id, this.blocks);
  String get introKey => pairGuideKey(id);
}

class PairGuide {
  final Synastry synastry;

  /// Count of inter-chart aspects per area: (supportive, straining).
  final Map<PairArea, ({int supportive, int straining})> overview;
  final List<GuideChapter> chapters;

  /// Moon sign uncertain (no birth time): its need and element pair are left out.
  final bool firstMoonUncertain;
  final bool secondMoonUncertain;

  const PairGuide._(this.synastry, this.overview, this.chapters, this.firstMoonUncertain, this.secondMoonUncertain);

  GuideChapter chapter(GuideChapterId id) => chapters.firstWhere((c) => c.id == id);

  bool get anyMoonUncertain => firstMoonUncertain || secondMoonUncertain;
  bool get anyTimeUnknown => !synastry.first.timeKnown || !synastry.second.timeKnown;

  factory PairGuide.of(Synastry s) {
    final facts = [for (final f in synastryFactorsOf(s)) if (f.aspect != null) f];
    final overview = {for (final a in PairArea.values) a: (supportive: 0, straining: 0)};
    for (final f in facts) {
      final tone = toneOf(f.aspect!);
      for (final area in areasOf(f.aspect!)) {
        final c = overview[area]!;
        overview[area] = tone == PairTone.supportive
            ? (supportive: c.supportive + 1, straining: c.straining)
            : (supportive: c.supportive, straining: c.straining + 1);
      }
    }

    // Each aspect text once, with every fact that leads to it, heaviest first.
    final byKey = <String, List<Factor>>{};
    for (final f in facts) {
      byKey.putIfAbsent(f.key, () => []).add(f);
    }
    List<GuideBlock> blocks(PairTone tone) =>
        [for (final e in byKey.entries) if (toneOf(e.value.first.aspect!) == tone) GuideBlock(e.key, facts: e.value)]
          ..sort((a, b) => b.weight.compareTo(a.weight));
    List<GuideBlock> links(Set<PairArea> areas) => ([
          for (final e in byKey.entries)
            if (areasOf(e.value.first.aspect!).any(areas.contains)) GuideBlock(e.key, facts: e.value, linkOnly: true),
        ]..sort((a, b) => b.weight.compareTo(a.weight)))
            .take(maxGuideLinks)
            .toList();

    final firstUncertain = moonSignUncertain(s.first), secondUncertain = moonSignUncertain(s.second);
    List<GuideBlock> needs(List<NeedPoint> points) {
      final a = {for (final p in points) p: _needSign(s.first, p, firstUncertain)};
      final b = {for (final p in points) p: _needSign(s.second, p, secondUncertain)};
      return [
        for (final p in points)
          if (a[p] case final sign?) GuideBlock(pairNeedKey(p, sign), need: PersonNeed(true, p, sign), bothPeople: b[p] == sign),
        for (final p in points)
          if (b[p] case final sign? when sign != a[p]) GuideBlock(pairNeedKey(p, sign), need: PersonNeed(false, p, sign)),
      ];
    }
    List<GuideBlock> elements(List<Body> bodies) => [
          for (final b in bodies)
            if (s.first.positions[b] != null &&
                s.second.positions[b] != null &&
                !(b == Body.moon && (firstUncertain || secondUncertain)))
              () {
                final e = ElementPair(b, s.first.positions[b]!.sign.element, s.second.positions[b]!.sign.element);
                return GuideBlock(e.key, elements: e);
              }(),
        ];

    return PairGuide._(s, overview, [
      const GuideChapter(GuideChapterId.overview, []),
      GuideChapter(GuideChapterId.strengths, blocks(PairTone.supportive)),
      GuideChapter(GuideChapterId.cautions, blocks(PairTone.straining)),
      GuideChapter(GuideChapterId.talk, [...needs(const [NeedPoint.mercury]), ...elements(const [Body.mercury]), ...links({PairArea.talk})]),
      GuideChapter(GuideChapterId.respect, [...needs(const [NeedPoint.sun]), ...elements(const [Body.sun]), ...links({PairArea.respect})]),
      GuideChapter(GuideChapterId.needs, [
        ...needs(const [NeedPoint.moon, NeedPoint.venus, NeedPoint.mars, NeedPoint.dsc]),
        ...elements(const [Body.moon, Body.venus, Body.mars]),
        ...links({PairArea.feeling, PairArea.love, PairArea.energy}),
      ]),
      const GuideChapter(GuideChapterId.periods, []),
    ], firstUncertain, secondUncertain);
  }

  static Sign? _needSign(Chart c, NeedPoint p, bool moonUncertain) {
    if (p == NeedPoint.dsc) {
      final asc = c.asc;
      return asc == null ? null : Sign.ofLongitude(asc + 180);
    }
    if (p == NeedPoint.moon && moonUncertain) return null;
    return c.positions[p.body!]?.sign;
  }
}
