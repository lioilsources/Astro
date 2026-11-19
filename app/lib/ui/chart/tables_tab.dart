import 'package:astro_core/astro_core.dart';
import 'package:astro_core/content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/content_repository.dart';
import '../../l10n/app_localizations.dart';
import '../../state.dart';
import '../entry_view.dart';
import '../format.dart';
import 'house_compare.dart';

class TablesTab extends ConsumerStatefulWidget {
  final Chart chart;
  const TablesTab(this.chart, {super.key});
  @override
  ConsumerState<TablesTab> createState() => _TablesTabState();
}

class _TablesTabState extends ConsumerState<TablesTab> {
  HouseSystem? _system;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final content = ref.watch(contentProvider).value ?? const ContentRepository({}, []);
    final c = widget.chart;
    final houses = _system == null ? c.houses : c.housesFor(_system!);
    final t = Theme.of(context).textTheme;

    Widget header(String title, String glossaryKey) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 8, 4),
          child: Row(children: [
            Expanded(child: Text(title, style: t.titleMedium)),
            IconButton(
              icon: const Icon(Icons.help_outline, size: 20),
              onPressed: () => showEntry(context, content['glossary/$glossaryKey'], title: title),
            ),
          ]),
        );

    int? houseOf(Body b) => houses?.cusps == null ? null : houses!.houseOf(c.positions[b]!.lon);

    return ListView(children: [
      header(l.positions, 'planet'),
      for (final b in c.bodies)
        ListTile(
          dense: true,
          leading: SizedBox(width: 28, child: Center(child: glyphText(bodyGlyph[b]!, size: 20))),
          title: Text('${l.body(b)}  ${lonLabel(l, c.positions[b]!.lon)}${c.positions[b]!.retrograde ? ' ${l.retrogradeShort}' : ''}'),
          subtitle: Text('${c.positions[b]!.lat.toStringAsFixed(2)}° · ${c.positions[b]!.speed.toStringAsFixed(3)}°/d'
              '${houseOf(b) != null ? ' · ${l.houseN(houseOf(b)!)}' : ''}'),
          onTap: () {
            final id = contentIdOf(b);
            final h = houseOf(b);
            final shadowFirst = (c.states[b]?.score ?? 0) < 0;
            showEntry(context, content['planet_in_sign/$id/${c.positions[b]!.sign.name}'],
                title: '${l.body(b)} – ${l.sign(c.positions[b]!.sign)}',
                shadowFirst: shadowFirst,
                extra: [
                  if (h != null) const Divider(),
                  if (h != null) EntryView(content['planet_in_house/$id/$h'], fallbackTitle: '${l.body(b)} – ${l.houseN(h)}', shadowFirst: shadowFirst),
                ]);
          },
        ),
      header(l.houses, 'house_system'),
      if (houses == null)
        Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text(l.noHouses))
      else ...[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(children: [
            Expanded(
              child: DropdownButton<HouseSystem>(
                isExpanded: true,
                value: houses.system,
                items: [for (final h in HouseSystem.values) DropdownMenuItem(value: h, child: Text(l.house(h)))],
                onChanged: (v) => setState(() => _system = v),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => HouseCompareScreen(c))),
              child: Text(l.compareSystems),
            ),
          ]),
        ),
        if (!houses.defined)
          Padding(padding: const EdgeInsets.all(16), child: Text(l.polarHouses))
        else
          for (var i = 0; i < 12; i++)
            ListTile(
              dense: true,
              leading: SizedBox(width: 28, child: Center(child: Text('${i + 1}', style: t.titleSmall))),
              title: Text(lonLabel(l, houses.cusps![i])),
              subtitle: Text('${l.houseSize} ${houses.sizes[i].toStringAsFixed(1)}°'),
              trailing: glyphText(signGlyph[Sign.ofLongitude(houses.cusps![i]).index]),
              onTap: () => showEntry(context, content['sign_on_cusp/${i + 1}/${Sign.ofLongitude(houses.cusps![i]).name}'],
                  title: '${l.sign(Sign.ofLongitude(houses.cusps![i]))} – ${l.houseN(i + 1)}'),
            ),
      ],
      header(l.aspects, 'aspect'),
      for (final a in c.aspects)
        ListTile(
          dense: true,
          leading: SizedBox(width: 28, child: Center(child: glyphText(aspectGlyph[a.type]!, size: 18))),
          title: Text('${l.point(a.a)} ${l.aspect(a.type)} ${l.point(a.b)}'),
          subtitle: Text('orb ${formatDm(a.orb)}${a.applying ? ' ↗' : ' ↘'}'),
          onTap: () {
            final k = aspectKey(a);
            showEntry(context, k == null ? null : content[k], title: '${l.point(a.a)} ${l.aspect(a.type)} ${l.point(a.b)}');
          },
          onLongPress: () => showEntry(context, content['glossary/${a.type.name}'], title: l.aspect(a.type)),
        ),
      header(l.planetStates, 'domicile'),
      for (final b in Body.planets)
        if (c.states[b] != null)
          ListTile(
            dense: true,
            leading: SizedBox(width: 28, child: Center(child: glyphText(bodyGlyph[b]!, size: 20))),
            title: Text(l.body(b)),
            subtitle: Text(l.dignityName(c.states[b]!.dignity.name)),
            trailing: Text('${c.states[b]!.score > 0 ? '+' : ''}${c.states[b]!.score}', style: t.titleSmall),
          ),
      const SizedBox(height: 32),
    ]);
  }
}
