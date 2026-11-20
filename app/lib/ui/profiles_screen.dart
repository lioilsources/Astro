import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/profile.dart';
import '../l10n/app_localizations.dart';
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
      appBar: AppBar(title: Text(l.navProfiles), actions: [
        IconButton(
          tooltip: l.synastryTitle,
          icon: const Icon(Icons.compare_arrows),
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SynastryScreen())),
        ),
      ]),
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
            : ListView(children: [for (final p in list) _ProfileTile(p)]),
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
