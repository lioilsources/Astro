import 'package:astro_core/content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';
import '../logic/filter.dart';
import '../state.dart';
import 'format.dart';

/// Renders one text with its three layers under the user's filter.
/// Hidden passages leave a "Skryto: …" line instead of disappearing (plan 5.1).
class EntryView extends ConsumerWidget {
  final ContentEntry? entry;
  final bool shadowFirst;
  final String? fallbackTitle;
  final bool showTitle;
  final List<Widget> extra;
  const EntryView(
    this.entry, {
    super.key,
    this.shadowFirst = false,
    this.fallbackTitle,
    this.showTitle = true,
    this.extra = const [],
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final e = entry;
    if (e == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showTitle && fallbackTitle != null)
              Text(fallbackTitle!, style: t.titleMedium),
            Text(
              l.textMissing,
              style: t.bodySmall?.copyWith(fontStyle: FontStyle.italic),
            ),
            ...extra,
          ],
        ),
      );
    }
    final f = ref.watch(filterProvider).apply(e);
    final shadow = f.showShadow
        ? Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.shadowTitle, style: t.labelLarge),
                const SizedBox(height: 4),
                Text(e.shadow, style: t.bodyMedium),
              ],
            ),
          )
        : null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showTitle) Text(e.title, style: t.titleMedium),
          if (e.keywords.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                e.keywords.join(' · '),
                style: t.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          if (shadowFirst && shadow != null) shadow,
          const SizedBox(height: 6),
          Text(e.text, style: t.bodyMedium),
          if (!shadowFirst && shadow != null) shadow,
          for (final h in f.visibleHard)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: Theme.of(context).colorScheme.outline,
                    width: 3,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.topics(h.topics), style: t.labelSmall),
                  Text(h.text, style: t.bodyMedium),
                ],
              ),
            ),
          if (f.hiddenCount > 0) HiddenLine(f),
          ...extra,
        ],
      ),
    );
  }
}

class HiddenLine extends StatelessWidget {
  final FilteredEntry f;
  const HiddenLine(this.f, {super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.hiddenPassages(f.hiddenCount, l.topics(f.hiddenTopics)),
            style: t.bodySmall?.copyWith(fontStyle: FontStyle.italic),
          ),
          if (f.hiddenTopics.any((x) => x != 'shadow')) const HelpLink(),
        ],
      ),
    );
  }
}

/// Link to professional help shown next to hidden passages and in gentle mode.
/// Czech crisis line for adults, verified 2026-11-20 (linkapsychickepomoci.cz).
class HelpLink extends StatelessWidget {
  const HelpLink({super.key});
  static final phone = Uri(scheme: 'tel', path: '116123');
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () => launchUrl(phone),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        AppLocalizations.of(context).helpLink,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          decoration: TextDecoration.underline,
        ),
      ),
    ),
  );
}

/// Opens one text in a bottom sheet.
void showEntry(
  BuildContext context,
  ContentEntry? entry, {
  String? title,
  bool shadowFirst = false,
  List<Widget> extra = const [],
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (c) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      builder: (c, sc) => ListView(
        controller: sc,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
        children: [
          EntryView(
            entry,
            fallbackTitle: title,
            shadowFirst: shadowFirst,
            extra: extra,
          ),
        ],
      ),
    ),
  );
}

Text glyphText(String g, {double size = 18, Color? color}) => Text(
  g,
  style: glyphStyle.copyWith(fontSize: size, color: color),
);
