import 'package:astro_core/journal.dart';

import '../../l10n/app_localizations.dart';
import '../format.dart';

/// Czech decimal comma and a real minus sign.
String fmtNum(double v, [int digits = 2]) => v.toStringAsFixed(digits).replaceAll('.', ',').replaceAll('-', '−');

/// Share 0–1 as percent; zero hits of 10 000 shown as "< 0,01 %".
String fmtShare(double share, {int permutations = defaultPermutations}) {
  if (share == 0) return '< ${fmtNum(100 / permutations, 2)} %';
  final pct = share * 100;
  return '${fmtNum(pct, pct < 1 ? 2 : (pct < 10 ? 1 : 0))} %';
}

String fmtDay(String dayKey) => fmtDate(dateOfDayNumber(parseDayKey(dayKey)));

String ratingLabel(AppLocalizations l, int r) =>
    '${r > 0 ? '+' : (r < 0 ? '−' : '')}${r.abs()} ${l.journalRatingValue(switch (r) { -2 => 'm2', -1 => 'm1', 0 => 'zero', 1 => 'p1', _ => 'p2' })}';
