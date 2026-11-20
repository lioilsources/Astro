import 'package:astro_core/astro_core.dart';
import 'package:astro_core/content.dart';
import 'package:astro_core/journal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/places.dart' show fold;
import '../../data/profile.dart';
import '../../journal_state.dart';
import '../../l10n/app_localizations.dart';
import '../../state.dart';
import 'journal_format.dart';

/// Opens the rating form for [day]; [corrects] makes it a correction of a closed record.
Future<void> showRatingSheet(BuildContext context, Profile profile, Chart chart, String day, {DayRating? initial, String? corrects}) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: RatingForm(profile: profile, chart: chart, day: day, initial: initial, corrects: corrects),
      ),
    );

class RatingForm extends ConsumerStatefulWidget {
  final Profile profile;
  final Chart chart;
  final String day;
  final DayRating? initial;
  final String? corrects;
  const RatingForm({super.key, required this.profile, required this.chart, required this.day, this.initial, this.corrects});

  @override
  ConsumerState<RatingForm> createState() => _RatingFormState();
}

class _RatingFormState extends ConsumerState<RatingForm> {
  late int _rating = widget.initial?.rating ?? 0;
  late final List<String> _tags = [...?widget.initial?.tags];
  late final _note = TextEditingController(text: widget.initial?.note ?? '');
  String? _error;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    try {
      await ref
          .read(journalProvider(widget.profile.id).notifier)
          .rate(widget.chart, day: widget.day, rating: _rating, tags: _tags, note: _note.text, corrects: widget.corrects);
      if (mounted) Navigator.pop(context);
    } on LogRuleError catch (e) {
      setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final traits = ref.watch(contentProvider).value?.traits ?? const <Trait>[];
    String name(String id) => traits.where((x) => x.id == id).firstOrNull?.name ?? id;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(l.journalRatingLabel(fmtDay(widget.day)), style: t.titleMedium),
        if (widget.corrects != null) Padding(padding: const EdgeInsets.only(top: 4), child: Text(l.journalClosedNote, style: t.bodySmall)),
        const SizedBox(height: 12),
        SegmentedButton<int>(
          showSelectedIcon: false,
          segments: [
            for (var r = minRating; r <= maxRating; r++) ButtonSegment(value: r, label: Text(r > 0 ? '+$r' : (r < 0 ? '−${-r}' : '0'))),
          ],
          selected: {_rating},
          onSelectionChanged: (s) => setState(() => _rating = s.first),
        ),
        Padding(padding: const EdgeInsets.only(top: 4), child: Text(ratingLabel(l, _rating), style: t.bodySmall)),
        const SizedBox(height: 16),
        Text(l.journalTags, style: t.labelLarge),
        Wrap(spacing: 6, children: [
          for (final id in _tags) InputChip(label: Text(name(id)), onDeleted: () => setState(() => _tags.remove(id))),
        ]),
        Autocomplete<Trait>(
          displayStringForOption: (x) => x.name,
          optionsBuilder: (v) {
            final q = fold(v.text.trim());
            if (q.isEmpty) return const [];
            return traits.where((x) => !_tags.contains(x.id) && [x.name, ...x.synonyms].any((n) => fold(n).contains(q))).take(8);
          },
          onSelected: (x) => setState(() => _tags.add(x.id)),
          fieldViewBuilder: (context, controller, focus, submit) => TextField(
            controller: controller,
            focusNode: focus,
            decoration: InputDecoration(labelText: l.journalTagSearch),
            onSubmitted: (_) {
              submit();
              controller.clear();
            },
          ),
        ),
        const SizedBox(height: 12),
        TextField(controller: _note, decoration: InputDecoration(labelText: l.journalNote), maxLines: 3, minLines: 1),
        if (_error != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_error!, style: t.bodySmall?.copyWith(color: Theme.of(context).colorScheme.error))),
        const SizedBox(height: 16),
        Align(alignment: Alignment.centerRight, child: FilledButton(onPressed: _save, child: Text(l.journalSave))),
      ]),
    );
  }
}
