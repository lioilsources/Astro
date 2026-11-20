import 'package:astro_core/astro_core.dart';
import 'package:astro_core/content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/content_repository.dart';
import '../../l10n/app_localizations.dart';
import '../../state.dart';
import '../entry_view.dart';
import '../format.dart';
import '../wheel.dart';

/// The natal wheel with a switch for fixed-star markers on the outer rim (plan 10.6).
class WheelWithStars extends StatefulWidget {
  final Chart chart;

  /// Aspect pattern to highlight (R1).
  final ChartPattern? highlight;
  const WheelWithStars(this.chart, {super.key, this.highlight});
  @override
  State<WheelWithStars> createState() => _WheelWithStarsState();
}

class _WheelWithStarsState extends State<WheelWithStars> {
  bool _stars = false;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = widget.chart;
    return Column(children: [
      ChartWheel(c, stars: _stars ? c.starLons : null, starHits: {for (final s in c.starContacts) s.star.id}, highlight: widget.highlight),
      SwitchListTile(
        dense: true,
        contentPadding: EdgeInsets.zero,
        title: Text(l.starsOnWheel),
        value: _stars,
        onChanged: (v) => setState(() => _stars = v),
      ),
    ]);
  }
}

/// "Stálice" table: conjunctions (star, longitude, with what, orb), then all 32 stars.
class StarsTable extends ConsumerWidget {
  final Chart chart;
  final Widget header;
  const StarsTable(this.chart, {super.key, required this.header});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final content = ref.watch(contentProvider).value ?? const ContentRepository({}, []);
    final filter = ref.watch(filterProvider);
    final filtered = filter.hideShadow || filter.hiddenTopics.isNotEmpty;
    final contacts = chart.starContacts;

    void open(FixedStar s, List<StarContact> mine) => showEntry(
          context,
          content['star/${s.id}'],
          title: l.starName(s.id),
          extra: [
            for (final c in mine) ...[
              const Divider(),
              EntryView(content[starTargetKey(c.point)], fallbackTitle: '${l.starName(s.id)} – ${l.point(c.point)}'),
            ],
          ],
        );

    final sorted = chart.starLons.entries.toList()..sort((a, b) => a.value.compareTo(b.value));
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      header,
      if (filtered) Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text(l.starsFilterNote, style: t.bodySmall)),
      if (contacts.isEmpty) Padding(padding: const EdgeInsets.fromLTRB(16, 4, 16, 0), child: Text(l.starsNone, style: t.bodyMedium)),
      for (final c in contacts)
        ListTile(
          dense: true,
          leading: SizedBox(width: 28, child: Center(child: glyphText(pointGlyph(c.point), size: 18))),
          title: Text('${l.starName(c.star.id)}  ${lonLabel(l, c.starLon)}'),
          subtitle: Text(l.starContact(l.point(c.point), formatDm(c.orb))),
          onTap: () => open(c.star, contacts.where((x) => x.star == c.star).toList()),
        ),
      ExpansionTile(
        title: Text(l.starsAll, style: t.bodyMedium),
        children: [
          for (final e in sorted)
            ListTile(
              dense: true,
              title: Text(l.starName(e.key.id)),
              trailing: Text(lonLabel(l, e.value)),
              onTap: () => open(e.key, contacts.where((x) => x.star == e.key).toList()),
            ),
        ],
      ),
    ]);
  }
}
