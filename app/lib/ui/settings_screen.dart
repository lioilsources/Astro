import 'package:astro_core/astro_core.dart';
import 'package:astro_core/content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/settings.dart';
import '../l10n/app_localizations.dart';
import '../state.dart';
import 'entry_view.dart';
import 'format.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final s = ref.watch(settingsProvider).value ?? const AppSettings();
    final n = ref.read(settingsProvider.notifier);
    return Scaffold(
      appBar: AppBar(title: Text(l.navSettings)),
      body: ListView(children: [
        Padding(padding: const EdgeInsets.fromLTRB(16, 16, 16, 4), child: Text(l.settingsFilter, style: t.titleMedium)),
        SwitchListTile(
          title: Text(l.gentleMode),
          subtitle: Text(l.gentleModeDesc),
          value: s.gentle,
          onChanged: (v) => n.change((x) => x.copyWith(hiddenTopics: v ? hardTopics.toSet() : const {})),
        ),
        if (s.gentle) const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: HelpLink()),
        for (final topic in hardTopics)
          CheckboxListTile(
            dense: true,
            title: Text(l.hardTopicName(topic)),
            value: s.hiddenTopics.contains(topic),
            onChanged: (v) => n.change((x) => x.copyWith(hiddenTopics: v == true ? {...x.hiddenTopics, topic} : ({...x.hiddenTopics}..remove(topic)))),
          ),
        CheckboxListTile(
          dense: true,
          title: Text(l.settingsShadow),
          value: s.hideShadow,
          onChanged: (v) => n.change((x) => x.copyWith(hideShadow: v)),
        ),
        const Divider(),
        ListTile(
          title: Text(l.settingsHouses),
          trailing: DropdownButton<HouseSystem?>(
            value: s.defaultHouseSystem,
            items: [
              DropdownMenuItem(value: null, child: Text(l.houseSystemAuto)),
              for (final h in HouseSystem.values) DropdownMenuItem(value: h, child: Text(l.house(h))),
            ],
            onChanged: (v) => n.change((x) => v == null ? x.copyWith(clearDefaultHouseSystem: true) : x.copyWith(defaultHouseSystem: v)),
          ),
        ),
        SwitchListTile(title: Text(l.settingsOrbs), value: s.tightOrbs, onChanged: (v) => n.change((x) => x.copyWith(tightOrbs: v))),
        SwitchListTile(title: Text(l.settingsNode), value: s.trueNode, onChanged: (v) => n.change((x) => x.copyWith(trueNode: v))),
        const Divider(),
        ListTile(
          title: Text(l.settingsAbout),
          onTap: () => showDialog<void>(
            context: context,
            builder: (c) => AlertDialog(content: Text(l.aboutText), actions: [TextButton(onPressed: () => Navigator.pop(c), child: Text(l.ok))]),
          ),
        ),
        Padding(padding: const EdgeInsets.all(16), child: Text(signGlyph.join(' '), style: glyphStyle.copyWith(fontSize: 18))),
      ]),
    );
  }
}
