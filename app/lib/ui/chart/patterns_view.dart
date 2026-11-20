import 'package:astro_core/astro_core.dart';
import 'package:astro_core/content.dart';
import 'package:flutter/material.dart';

import '../../data/content_repository.dart';
import '../../l10n/app_localizations.dart';
import '../entry_view.dart';
import '../format.dart';
import '../wheel.dart';

extension PatternNames on AppLocalizations {
  /// "Velký trigon (oheň)", "Přemíra pevných znamení", "Mars bez aspektu".
  String pattern(ChartPattern p) => switch (p.kind) {
        PatternKind.grandTrine || PatternKind.kite => patternWithQuality(patternName(p.kind.name), elementName(p.element!.name)),
        PatternKind.tSquare || PatternKind.grandCross => patternWithQuality(patternName(p.kind.name), modalityName(p.modality!.name)),
        PatternKind.yod || PatternKind.cradle || PatternKind.mysticRectangle => patternName(p.kind.name),
        PatternKind.modalityExcess => modalityExcess(p.modality!.name),
        PatternKind.modalityLack => modalityLack(p.modality!.name),
        PatternKind.hemisphere => hemisphereEmphasis(p.hemisphere!.name),
        PatternKind.unaspected => unaspectedPlanet(body(p.bodies.single)),
      };

  /// Title of one pattern text (an apex key gets its own title).
  String patternKeyTitle(String key, ChartPattern p) {
    final parts = key.split('/');
    if (parts[1] == 't_square_apex' || parts[1] == 'yod_apex') {
      return patternApexTitle(bodyName(parts[2]), p.kind.name);
    }
    return pattern(p);
  }

  /// "Slunce, Mars, Saturn · vrchol: Mars".
  String patternMembers(ChartPattern p) => [
        p.bodies.map(body).join(', '),
        if (p.apexes.isNotEmpty) patternApex(p.apexes.map(body).join(', ')),
      ].join(' · ');
}

/// Bottom sheet with the pattern highlighted on the wheel and its texts.
void showPattern(BuildContext context, Chart chart, ChartPattern p, ContentRepository content) {
  final l = AppLocalizations.of(context);
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (c) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.8,
      maxChildSize: 0.95,
      builder: (c, sc) => ListView(
        controller: sc,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
        children: [
          Center(child: SizedBox(width: 280, child: ChartWheel(chart, highlight: p))),
          const SizedBox(height: 8),
          Text(l.patternMembers(p), style: Theme.of(context).textTheme.bodySmall),
          for (final k in patternKeysOf(p)) EntryView(content[k], fallbackTitle: l.patternKeyTitle(k, p)),
        ],
      ),
    ),
  );
}
