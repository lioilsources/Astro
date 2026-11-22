import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/profile.dart';
import '../data/pairs.dart';
import '../l10n/app_localizations.dart';
import '../pair_state.dart';
import '../state.dart';
import 'chart/chart_screen.dart';
import 'format.dart';
import 'profile_form.dart';
import 'synastry/synastry_screen.dart';

class ProfilesScreen extends ConsumerWidget {
  const ProfilesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final profiles = ref.watch(profilesProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l.navProfiles)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileForm())),
        icon: const Icon(Icons.add),
        label: Text(l.addProfile),
      ),
      body: profiles.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (list) => list.isEmpty
            ? Center(child: Padding(padding: const EdgeInsets.all(32), child: Text(l.profilesEmpty, textAlign: TextAlign.center)))
            : ListView(children: [_PairsSection(list), for (final p in list) _ProfileTile(p)]),
      ),
    );
  }
}

class _ProfileTile extends ConsumerWidget {
  final Profile profile;
  const _ProfileTile(this.profile);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final chart = ref.watch(chartProvider(profile));
    final m = profile.birth.moment;
    final sun = chart.positions[chart.bodies.first]!;
    return ListTile(
      leading: CircleAvatar(child: Text(signGlyph[sun.sign.index], style: glyphStyle.copyWith(fontSize: 20))),
      title: Text(profile.name),
      subtitle: Text('${m.day}. ${m.month}. ${m.year}${m.hour != null ? ' ${two(m.hour!)}:${two(m.minute ?? 0)}' : ''}'
          '${profile.birth.placeName != null ? ', ${profile.birth.placeName}' : ''}'),
      trailing: Text(l.sign(sun.sign)),
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChartScreen(profile))),
      onLongPress: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileForm(existing: profile))),
    );
  }
}

/// Saved pairs on top of the profiles (plan R9 6.1).
class _PairsSection extends ConsumerWidget {
  final List<Profile> profiles;
  const _PairsSection(this.profiles);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final byId = {for (final p in profiles) p.id: p};
    // A store that cannot be read shows no pairs; nothing is saved over it.
    final pairs = [for (final p in ref.watch(pairsProvider).value ?? const <Pair>[]) if (byId[p.firstId] != null && byId[p.secondId] != null) p];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
        child: Row(children: [
          Expanded(child: Text(l.pairsTitle, style: Theme.of(context).textTheme.titleMedium)),
          TextButton.icon(
            onPressed: profiles.length < 2 ? null : () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SynastryScreen())),
            icon: const Icon(Icons.add),
            label: Text(l.pairAdd),
          ),
        ]),
      ),
      for (final p in pairs)
        ListTile(
          leading: const Icon(Icons.compare_arrows),
          title: Text(l.synastryPairTitle(byId[p.firstId]!.name, byId[p.secondId]!.name)),
          subtitle: Text(l.relationshipName(p.relationship.name)),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => SynastryResultScreen(byId[p.firstId]!, byId[p.secondId]!, p.relationship)),
          ),
          onLongPress: () async {
            final name = l.synastryPairTitle(byId[p.firstId]!.name, byId[p.secondId]!.name);
            final ok = await showDialog<bool>(
              context: context,
              builder: (c) => AlertDialog(
                title: Text(l.pairDelete),
                content: Text(l.pairDeleteConfirm(name)),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(c, false), child: Text(l.cancel)),
                  TextButton(onPressed: () => Navigator.pop(c, true), child: Text(l.delete)),
                ],
              ),
            );
            if (ok == true) await ref.read(pairsProvider.notifier).remove(p.id);
          },
        ),
      const Divider(),
    ]);
  }
}
