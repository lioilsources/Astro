import 'package:astro_core/astro_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/profile.dart';
import '../../l10n/app_localizations.dart';
import '../../logic/reading.dart';
import '../../state.dart';
import '../entry_view.dart';
import '../format.dart';
import 'patterns_view.dart';

class ReadingTab extends ConsumerStatefulWidget {
  final Chart chart;
  final Profile profile;
  const ReadingTab(this.chart, this.profile, {super.key});
  @override
  ConsumerState<ReadingTab> createState() => _ReadingTabState();
}

class _ReadingTabState extends ConsumerState<ReadingTab> {
  bool _themes = false;

  String _sectionTitle(AppLocalizations l, String id) => switch (id) {
        'signs' => l.sectionSigns,
        'houses' => l.sectionHouses,
        'aspects' => l.sectionAspects,
        'cusps' => l.sectionCusps,
        'emphasis' => l.sectionEmphasis,
        'patterns' => l.patterns,
        _ => l.themeName(id),
      };

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final content = ref.watch(contentProvider);
    return content.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (repo) {
        final items = readingItems(widget.chart, repo);
        final sections = _themes ? byThemes(items) : bySections(items);
        return ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 32), children: [
          SegmentedButton<bool>(
            segments: [ButtonSegment(value: false, label: Text(l.readingBySections)), ButtonSegment(value: true, label: Text(l.readingByThemes))],
            selected: {_themes},
            onSelectionChanged: (s) => setState(() => _themes = s.first),
          ),
          if (widget.profile.catalogId != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(l.traditionNote)),
          for (final s in sections) ...[
            Padding(
              padding: const EdgeInsets.only(top: 20, bottom: 4),
              child: Text(_sectionTitle(l, s.id), style: Theme.of(context).textTheme.titleLarge),
            ),
            for (final i in s.items) EntryView(i.entry, shadowFirst: i.shadowFirst, fallbackTitle: _fallback(l, i)),
          ],
        ]);
      },
    );
  }

  String _fallback(AppLocalizations l, ReadingItem i) {
    final f = i.factor;
    if (f.pattern != null) return l.patternKeyTitle(f.key, f.pattern!);
    if (f.aspect != null) return '${l.point(f.aspect!.a)} ${l.aspect(f.aspect!.type)} ${l.point(f.aspect!.b)}';
    if (f.body != null && f.sign != null) return '${l.body(f.body!)} – ${l.sign(f.sign!)}';
    if (f.body != null && f.house != null) return '${l.body(f.body!)} – ${l.houseN(f.house!)}';
    if (f.sign != null && f.house != null) return '${l.sign(f.sign!)} – ${l.houseN(f.house!)}';
    return f.key;
  }
}
