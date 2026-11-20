import 'package:astro_core/content.dart';

/// What of an entry is shown under the user's filter (plan 5.1).
class FilteredEntry {
  final ContentEntry entry;
  final bool showShadow;
  final List<HardPassage> visibleHard;

  /// Topics of hidden passages (shadow counts as one passage with topic `shadow`).
  final List<String> hiddenTopics;
  const FilteredEntry(this.entry, this.showShadow, this.visibleHard, this.hiddenTopics);

  int get hiddenCount => hiddenTopics.length;
}

class ContentFilter {
  final Set<String> hiddenTopics;
  final bool hideShadow;
  const ContentFilter({this.hiddenTopics = const {}, this.hideShadow = false});

  static const none = ContentFilter();

  /// A passage is hidden when any of its topics is hidden.
  FilteredEntry apply(ContentEntry e) {
    final visible = <HardPassage>[];
    final hidden = <String>[];
    for (final h in e.hard) {
      final blocked = h.topics.where(hiddenTopics.contains).toList();
      if (blocked.isEmpty) {
        visible.add(h);
      } else {
        hidden.add(blocked.first);
      }
    }
    final shadowHidden = hideShadow && e.shadow.isNotEmpty;
    if (shadowHidden) hidden.insert(0, 'shadow');
    return FilteredEntry(e, !shadowHidden && e.shadow.isNotEmpty, visible, hidden);
  }
}
