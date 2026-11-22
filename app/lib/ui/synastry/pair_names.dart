import 'package:astro_core/astro_core.dart';
import 'package:astro_core/content.dart';

import '../../l10n/app_localizations.dart';
import '../format.dart';

/// Titles of inter-chart facts, needs and periods with the names of the two people.
class PairNames {
  final String first;
  final String second;
  const PairNames(this.first, this.second);

  String of(bool ofFirst) => ofFirst ? first : second;

  String point(AppLocalizations l, ChartPoint p, bool ofFirst) => l.synastryPointOf(l.point(p), of(ofFirst));

  String aspect(AppLocalizations l, Aspect a) => '${point(l, a.a, true)} ${l.aspect(a.type)} ${point(l, a.b, false)}';

  String overlay(AppLocalizations l, HouseOverlay o) =>
      '${l.synastryPointOf(l.body(o.body), of(o.ofFirst))} – ${l.synastryPointOf(l.houseN(o.house), of(!o.ofFirst))}';

  String fact(AppLocalizations l, Factor f) => f.aspect != null ? aspect(l, f.aspect!) : overlay(l, f.overlay!);

  String facts(AppLocalizations l, List<Factor> fs) => fs.map((f) => fact(l, f)).join(' · ');

  /// "Petr · Měsíc v Raku"; both names when the need holds for both.
  String need(AppLocalizations l, GuideBlock b) {
    final n = b.need!;
    final who = b.bothPeople ? l.synastryPairTitle(first, second) : of(n.ofFirst);
    final pt = n.point.body == null ? l.pairDescendant : l.body(n.point.body!);
    return l.pairNeedTitle(who, pt, l.signIn(n.sign.name));
  }

  String elements(AppLocalizations l, ElementPair e) =>
      l.pairElementsTitle(l.body(e.body), first, l.elementName(e.first.name), second, l.elementName(e.second.name));

  /// Title of any guide block.
  String block(AppLocalizations l, GuideBlock b) =>
      b.need != null ? need(l, b) : b.elements != null ? elements(l, b.elements!) : facts(l, b.facts);

  String periodTitle(AppLocalizations l, PairPeriod p) {
    final s = p.series;
    return l.periodTitle(l.body(s.transiting), l.aspect(s.type), l.point(s.target));
  }

  String period(AppLocalizations l, PairPeriod p) => l.periodOf(of(p.ofFirst), periodTitle(l, p));
}

/// "6/2027" in the phone's time zone.
String monthYear(double jd) {
  final d = localOfJd(jd);
  return '${d.month}/${d.year}';
}
