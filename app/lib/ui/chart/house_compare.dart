import 'package:astro_core/astro_core.dart';
import 'package:astro_core/content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/content_repository.dart';
import '../../l10n/app_localizations.dart';
import '../../state.dart';
import '../entry_view.dart';
import '../format.dart';

/// Two house systems side by side (plan 3.3), default Placidus × Porphyry.
class HouseCompareScreen extends ConsumerStatefulWidget {
  final Chart chart;
  const HouseCompareScreen(this.chart, {super.key});
  @override
  ConsumerState<HouseCompareScreen> createState() => _HouseCompareScreenState();
}

class _HouseCompareScreenState extends ConsumerState<HouseCompareScreen> {
  HouseSystem a = HouseSystem.placidus, b = HouseSystem.porphyry;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final content = ref.watch(contentProvider).value ?? const ContentRepository({}, []);
    final c = widget.chart;
    final ha = c.housesFor(a)!, hb = c.housesFor(b)!;
    Widget picker(HouseSystem v, ValueChanged<HouseSystem> on) => DropdownButton<HouseSystem>(
          value: v,
          items: [for (final h in HouseSystem.values) DropdownMenuItem(value: h, child: Text(l.house(h)))],
          onChanged: (x) => setState(() => on(x!)),
        );
    final changes = [
      if (ha.defined && hb.defined)
        for (final body in c.bodies)
          if (ha.houseOf(c.positions[body]!.lon) != hb.houseOf(c.positions[body]!.lon)) body
    ];
    return Scaffold(
      appBar: AppBar(title: Text(l.compareSystems)),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Row(children: [Expanded(child: picker(a, (x) => a = x)), const Text('×'), const SizedBox(width: 12), Expanded(child: picker(b, (x) => b = x))]),
        if (!ha.defined || !hb.defined) Text(l.polarHouses),
        if (ha.defined && hb.defined) ...[
          Table(
            columnWidths: const {0: FixedColumnWidth(32)},
            children: [
              TableRow(children: [const SizedBox(), Text(l.house(a), style: t.labelLarge), Text(l.house(b), style: t.labelLarge), Text('Δ', style: t.labelLarge)]),
              for (var i = 0; i < 12; i++)
                TableRow(children: [
                  Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Text('${i + 1}')),
                  _cusp(ha.cusps![i]),
                  _cusp(hb.cusps![i]),
                  Text('${angDist(ha.cusps![i], hb.cusps![i]).toStringAsFixed(1)}°'),
                ]),
            ],
          ),
          const SizedBox(height: 16),
          Text('${l.houseSize} (${l.house(a)} / ${l.house(b)})', style: t.labelLarge),
          Text([for (var i = 0; i < 12; i++) '${i + 1}: ${ha.sizes[i].round()}°/${hb.sizes[i].round()}°'].join('  ')),
          const SizedBox(height: 16),
          Text(l.changesHouse, style: t.titleMedium),
          if (changes.isEmpty) const Text('—'),
          for (final body in changes) ...[
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: glyphText(bodyGlyph[body]!, size: 20),
              title: Text('${l.body(body)}: ${l.houseN(ha.houseOf(c.positions[body]!.lon))} → ${l.houseN(hb.houseOf(c.positions[body]!.lon))}'),
            ),
            EntryView(content['planet_in_house/${contentIdOf(body)}/${ha.houseOf(c.positions[body]!.lon)}'],
                fallbackTitle: '${l.house(a)}: ${l.houseN(ha.houseOf(c.positions[body]!.lon))}'),
            EntryView(content['planet_in_house/${contentIdOf(body)}/${hb.houseOf(c.positions[body]!.lon)}'],
                fallbackTitle: '${l.house(b)}: ${l.houseN(hb.houseOf(c.positions[body]!.lon))}'),
            const Divider(),
          ],
        ],
      ]),
    );
  }
}

Widget _cusp(double lon) => Row(children: [Text('${formatInSign(lon)} '), glyphText(signGlyph[Sign.ofLongitude(lon).index], size: 14)]);
