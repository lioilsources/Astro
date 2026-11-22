import 'package:astro_core/astro_core.dart';
import 'package:astro_core/content.dart';
import 'package:flutter/material.dart';

import '../../data/content_repository.dart';
import '../../l10n/app_localizations.dart';
import '../entry_view.dart';
import 'pair_names.dart';

/// Number of blocks shown in strengths and cautions before "Zobrazit další".
const guideFirstBlocks = 5;

/// "Průvodce" tab (plan R9 6.2): the chapters of [PairGuide] in one list.
class PairGuideTab extends StatelessWidget {
  final PairGuide guide;
  final PairTimeline? timeline;
  final PairNames names;
  final ContentRepository content;
  final bool showPartner;
  final double now;
  final VoidCallback onOpenTimeline;

  /// Shown on top (the twins card).
  final List<Widget> leading;
  const PairGuideTab({
    this.leading = const [],
    super.key,
    required this.guide,
    required this.timeline,
    required this.names,
    required this.content,
    required this.showPartner,
    required this.now,
    required this.onOpenTimeline,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    Widget intro(GuideChapterId id) {
      final e = content[pairGuideKey(id)];
      return e == null ? const SizedBox.shrink() : Padding(padding: const EdgeInsets.only(bottom: 4), child: Text(e.text, style: t.bodyMedium));
    }

    Widget heading(GuideChapterId id) =>
        Padding(padding: const EdgeInsets.only(top: 24, bottom: 6), child: Text(l.pairChapter(id.name), style: t.titleLarge));

    final children = <Widget>[
      ...leading,
      _Overview(guide: guide, content: content),
      if (guide.anyTimeUnknown && content['pair_guide/no_birth_time'] != null)
        Padding(padding: const EdgeInsets.only(top: 8), child: Text(content['pair_guide/no_birth_time']!.text, style: t.bodySmall)),
    ];
    for (final c in guide.chapters) {
      switch (c.id) {
        case GuideChapterId.overview:
          continue;
        case GuideChapterId.periods:
          children
            ..add(heading(c.id))
            ..add(intro(c.id))
            ..add(_NextPeriods(timeline: timeline, names: names, now: now))
            ..add(Align(alignment: Alignment.centerLeft, child: TextButton(onPressed: onOpenTimeline, child: Text(l.pairOpenTimeline))));
        case GuideChapterId.strengths || GuideChapterId.cautions:
          children
            ..add(heading(c.id))
            ..add(intro(c.id))
            ..add(_ExpandableBlocks(
              blocks: c.blocks,
              names: names,
              content: content,
              showPartner: showPartner,
              shadowFirst: c.id == GuideChapterId.cautions,
            ));
          if (c.id == GuideChapterId.cautions) children.add(const HelpLink());
        default:
          final full = [for (final b in c.blocks) if (!b.linkOnly) b];
          final links = [for (final b in c.blocks) if (b.linkOnly) b];
          children
            ..add(heading(c.id))
            ..add(intro(c.id))
            ..addAll([for (final b in full) _BlockView(b, names: names, content: content, showPartner: showPartner)]);
          if (links.isNotEmpty) {
            children.add(Padding(padding: const EdgeInsets.only(top: 8), child: Text(l.pairSeeAlso, style: t.labelLarge)));
            for (final b in links) {
              final title = names.block(l, b);
              children.add(ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(title),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => showEntry(context, content[b.key], title: title, showPartner: showPartner),
              ));
            }
          }
      }
    }
    return ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 32), children: children);
  }
}

class _Overview extends StatelessWidget {
  final PairGuide guide;
  final ContentRepository content;
  const _Overview({required this.guide, required this.content});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final intro = content[pairGuideKey(GuideChapterId.overview)];
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(l.pairChapter('overview'), style: t.titleMedium)),
            IconButton(
              tooltip: l.pairMethod,
              icon: const Icon(Icons.help_outline, size: 20),
              onPressed: () => showEntry(context, content['pair_guide/method'], title: l.pairMethod),
            ),
          ]),
          for (final MapEntry(key: area, value: c) in guide.overview.entries)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(children: [
                SizedBox(width: 90, child: Text(l.pairArea(area.name), style: t.labelLarge)),
                Expanded(child: Text(l.pairAreaCounts(c.supportive, c.straining), style: t.bodyMedium)),
              ]),
            ),
          if (intro != null) Padding(padding: const EdgeInsets.only(top: 8, right: 8), child: Text(intro.text, style: t.bodySmall)),
        ]),
      ),
    );
  }
}

class _ExpandableBlocks extends StatefulWidget {
  final List<GuideBlock> blocks;
  final PairNames names;
  final ContentRepository content;
  final bool showPartner;
  final bool shadowFirst;
  const _ExpandableBlocks({required this.blocks, required this.names, required this.content, required this.showPartner, required this.shadowFirst});

  @override
  State<_ExpandableBlocks> createState() => _ExpandableBlocksState();
}

class _ExpandableBlocksState extends State<_ExpandableBlocks> {
  bool _all = false;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final showPartner = widget.showPartner;
    final shown = _all ? widget.blocks : widget.blocks.take(guideFirstBlocks).toList();
    final rest = widget.blocks.length - shown.length;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      for (final b in shown)
        _BlockView(b, names: widget.names, content: widget.content, showPartner: showPartner, shadowFirst: widget.shadowFirst),
      if (rest > 0) TextButton(onPressed: () => setState(() => _all = true), child: Text(l.pairShowMore(rest))),
    ]);
  }
}

class _BlockView extends StatelessWidget {
  final GuideBlock block;
  final PairNames names;
  final ContentRepository content;
  final bool showPartner;
  final bool shadowFirst;
  const _BlockView(this.block, {required this.names, required this.content, required this.showPartner, this.shadowFirst = false});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final title = names.block(l, block);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.only(top: 8), child: Text(title, style: Theme.of(context).textTheme.labelMedium)),
      EntryView(content[block.key], fallbackTitle: title, shadowFirst: shadowFirst, showPartner: showPartner),
    ]);
  }
}

/// The three nearest straining periods as short rows.
class _NextPeriods extends StatelessWidget {
  final PairTimeline? timeline;
  final PairNames names;
  final double now;
  const _NextPeriods({required this.timeline, required this.names, required this.now});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final tl = timeline;
    if (tl == null) return Text(l.computing, style: t.bodySmall);
    final next = tl.nextStraining(now).take(3).toList();
    if (next.isEmpty) return Text(l.pairNoStrain, style: t.bodyMedium);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(l.pairNextStrain, style: t.labelLarge),
      for (final p in next)
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text('${l.periodRange(monthYear(p.start), monthYear(p.end))} · ${names.period(l, p)}', style: t.bodyMedium),
        ),
    ]);
  }
}
