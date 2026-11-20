import 'package:astro_core/astro_core.dart';
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

const glyphStyle = TextStyle(fontFamily: 'NotoSansSymbols', fontFamilyFallback: ['NotoSansSymbols2']);

const bodyGlyph = {
  Body.sun: '☉', Body.moon: '☽', Body.mercury: '☿', Body.venus: '♀', Body.mars: '♂', Body.jupiter: '♃',
  Body.saturn: '♄', Body.uranus: '♅', Body.neptune: '♆', Body.pluto: '♇', Body.meanNode: '☊', Body.trueNode: '☊',
};
const signGlyph = ['♈', '♉', '♊', '♋', '♌', '♍', '♎', '♏', '♐', '♑', '♒', '♓'];
const aspectGlyph = {
  AspectType.conjunction: '☌', AspectType.sextile: '⚹', AspectType.square: '□', AspectType.trine: '△',
  AspectType.opposition: '☍', AspectType.quincunx: '⚻',
};

extension Names on AppLocalizations {
  String body(Body b) => bodyName(b.name);
  String point(ChartPoint p) => bodyName(p.id);
  String sign(Sign s) => signName(s.name);
  String aspect(AspectType a) => aspectName(a.name);
  String house(HouseSystem h) => houseSystemName(h.name);
  String topics(Iterable<String> ids) => ids.map((t) => t == 'shadow' ? shadowTitle.toLowerCase() : hardTopicName(t)).toSet().join(', ');
}

String pointGlyph(ChartPoint p) => p.body != null ? bodyGlyph[p.body]! : (p.angle == Angle.asc ? 'AC' : 'MC');

/// "22°21′ Panna"
String lonLabel(AppLocalizations l, double lon) => '${formatInSign(lon)} ${l.sign(Sign.ofLongitude(lon))}';

DateTime localOfJd(double jd) => dateTimeUtcFromJd(jd).toLocal();

String two(int v) => v.toString().padLeft(2, '0');
String fmtDate(DateTime d) => '${d.day}. ${d.month}. ${d.year}';
String fmtTime(DateTime d) => '${two(d.hour)}:${two(d.minute)}';
String fmtDateTime(DateTime d) => '${fmtDate(d)} ${fmtTime(d)}';
