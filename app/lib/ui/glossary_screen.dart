import 'package:astro_core/content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/places.dart' show fold;
import '../l10n/app_localizations.dart';
import '../state.dart';
import 'entry_view.dart';

class GlossaryScreen extends ConsumerStatefulWidget {
  const GlossaryScreen({super.key});
  @override
  ConsumerState<GlossaryScreen> createState() => _GlossaryScreenState();
}

class _GlossaryScreenState extends ConsumerState<GlossaryScreen> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final content = ref.watch(contentProvider).value;
    final entries = [
      for (final id in glossaryIds)
        if (content?['glossary/$id'] != null) content!['glossary/$id']!
    ]..sort((a, b) => fold(a.title).compareTo(fold(b.title)));
    final shown = entries.where((e) => _q.isEmpty || fold(e.title).contains(fold(_q)) || fold(e.text).contains(fold(_q))).toList();
    return Scaffold(
      appBar: AppBar(title: Text(l.navGlossary)),
      body: ListView(children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(decoration: InputDecoration(hintText: l.glossarySearch, prefixIcon: const Icon(Icons.search)), onChanged: (v) => setState(() => _q = v)),
        ),
        for (final e in shown)
          ListTile(
            title: Text(e.title),
            subtitle: Text(e.text, maxLines: 2, overflow: TextOverflow.ellipsis),
            onTap: () => showEntry(context, e),
          ),
      ]),
    );
  }
}
