import 'package:astro_core/astro_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/places.dart';
import '../data/profile.dart';
import '../journal_state.dart';
import '../l10n/app_localizations.dart';
import '../state.dart';
import 'format.dart';

class ProfileForm extends ConsumerStatefulWidget {
  final Profile? existing;
  const ProfileForm({super.key, this.existing});
  @override
  ConsumerState<ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends ConsumerState<ProfileForm> {
  final _name = TextEditingController();
  final _day = TextEditingController();
  final _month = TextEditingController();
  final _year = TextEditingController();
  final _hour = TextEditingController();
  final _minute = TextEditingController();
  final _place = TextEditingController();
  final _lat = TextEditingController();
  final _lon = TextEditingController();
  final _zone = TextEditingController(text: 'Europe/Prague');
  bool _timeUnknown = false;
  bool _manual = false;
  TimeBasis _basis = TimeBasis.zone;
  CalendarKind? _calendar;
  HouseSystem? _system;
  Place? _picked;
  List<Place> _suggestions = const [];
  String? _error;

  @override
  void initState() {
    super.initState();
    final p = widget.existing;
    if (p != null) {
      final m = p.birth.moment;
      _name.text = p.name;
      _day.text = '${m.day}';
      _month.text = '${m.month}';
      _year.text = '${m.year}';
      _timeUnknown = m.hour == null;
      if (m.hour != null) {
        _hour.text = '${m.hour}';
        _minute.text = two(m.minute ?? 0);
      }
      _place.text = p.birth.placeName ?? '';
      _lat.text = '${p.birth.lat}';
      _lon.text = '${p.birth.lon}';
      _zone.text = m.zone ?? 'Europe/Prague';
      _basis = m.basis;
      _calendar = m.calendar;
      _system = p.houseSystem;
      _manual = true;
    }
  }

  void _search(String q) async {
    final idx = await ref.read(placesProvider.future);
    setState(() {
      _picked = null;
      _suggestions = idx.search(q, limit: 8);
    });
  }

  void _pick(Place p) => setState(() {
        _picked = p;
        _place.text = p.name;
        _lat.text = p.lat.toStringAsFixed(4);
        _lon.text = p.lon.toStringAsFixed(4);
        _zone.text = p.zone;
        _suggestions = const [];
      });

  BirthData? _birth() {
    final d = int.tryParse(_day.text), mo = int.tryParse(_month.text), y = int.tryParse(_year.text);
    final lat = double.tryParse(_lat.text.replaceAll(',', '.')), lon = double.tryParse(_lon.text.replaceAll(',', '.'));
    final h = _timeUnknown ? null : int.tryParse(_hour.text);
    final mi = _timeUnknown ? null : (int.tryParse(_minute.text) ?? 0);
    if (d == null || mo == null || y == null || d < 1 || d > 31 || mo < 1 || mo > 12) return null;
    if (lat == null || lon == null || lat.abs() > 90 || lon.abs() > 180) return null;
    if (!_timeUnknown && (h == null || h < 0 || h > 23 || mi! < 0 || mi > 59)) return null;
    return BirthData(
      moment: LocalMoment(
        year: y,
        month: mo,
        day: d,
        hour: h,
        minute: mi,
        calendar: _calendar ?? defaultCalendar(y, mo, d),
        basis: _basis,
        zone: _basis == TimeBasis.zone ? _zone.text.trim() : null,
      ),
      lat: lat,
      lon: lon,
      placeName: _place.text.trim().isEmpty ? null : _place.text.trim(),
    );
  }

  Future<void> _save() async {
    final l = AppLocalizations.of(context);
    final b = _birth();
    if (b == null || _name.text.trim().isEmpty) {
      setState(() => _error = '${l.fieldName}, ${l.fieldDate}, ${l.fieldPlace}?');
      return;
    }
    ResolvedTime r;
    try {
      r = resolveMoment(b.moment, b.lon);
    } catch (e) {
      setState(() => _error = '${l.fieldZone}: $e');
      return;
    }
    final p = Profile(
      id: widget.existing?.id ?? DateTime.now().microsecondsSinceEpoch.toRadixString(36),
      name: _name.text.trim(),
      birth: b,
      houseSystem: _system,
      events: widget.existing?.events ?? const [],
    );
    if (r.dstAmbiguous && mounted) {
      await showDialog<void>(
        context: context,
        builder: (c) => AlertDialog(content: Text(l.dstAmbiguous), actions: [TextButton(onPressed: () => Navigator.pop(c), child: Text(l.ok))]),
      );
    }
    await ref.read(profilesProvider.notifier).upsert(p);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    final l = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        content: Text(l.deleteProfileConfirm(widget.existing!.name)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(l.cancel)),
          TextButton(onPressed: () => Navigator.pop(c, true), child: Text(l.delete)),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(profilesProvider.notifier).remove(widget.existing!.id);
      await ref.read(journalStoreProvider).delete(widget.existing!.id);
      if (mounted) Navigator.pop(context);
    }
  }

  Widget _num(TextEditingController c, String label, {double width = 72}) => SizedBox(
        width: width,
        child: TextField(
          controller: c,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9-]'))],
          decoration: InputDecoration(labelText: label),
          onChanged: (_) => setState(() {}),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final b = _birth();
    String? note;
    if (b != null) {
      try {
        final r = resolveMoment(b.moment, b.lon);
        if (r.basisUsed == TimeBasis.lmt && _basis == TimeBasis.zone) note = l.lmtNotice;
        if (r.dstAmbiguous) note = l.dstAmbiguous;
      } catch (_) {}
    }
    final y = int.tryParse(_year.text);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing == null ? l.addProfile : l.editProfile),
        actions: [if (widget.existing != null) IconButton(onPressed: _delete, icon: const Icon(Icons.delete_outline), tooltip: l.deleteProfile)],
      ),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        TextField(controller: _name, decoration: InputDecoration(labelText: l.fieldName)),
        const SizedBox(height: 16),
        Text(l.fieldDate, style: Theme.of(context).textTheme.labelLarge),
        Row(children: [_num(_day, 'D'), const SizedBox(width: 8), _num(_month, 'M'), const SizedBox(width: 8), _num(_year, 'R', width: 96)]),
        if (y != null && y < 1924)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: SegmentedButton<CalendarKind>(
              segments: [
                ButtonSegment(value: CalendarKind.gregorian, label: Text(l.calGregorian)),
                ButtonSegment(value: CalendarKind.julian, label: Text(l.calJulian)),
              ],
              selected: {_calendar ?? defaultCalendar(y, int.tryParse(_month.text) ?? 1, int.tryParse(_day.text) ?? 1)},
              onSelectionChanged: (s) => setState(() => _calendar = s.first),
            ),
          ),
        const SizedBox(height: 16),
        Text(l.fieldTime, style: Theme.of(context).textTheme.labelLarge),
        Row(children: [
          if (!_timeUnknown) ...[_num(_hour, 'h'), const SizedBox(width: 8), _num(_minute, 'min')],
          const Spacer(),
          FilterChip(label: Text(l.timeUnknown), selected: _timeUnknown, onSelected: (v) => setState(() => _timeUnknown = v)),
        ]),
        const SizedBox(height: 8),
        DropdownButtonFormField<TimeBasis>(
          initialValue: _basis,
          decoration: InputDecoration(labelText: l.timeBasis),
          items: [
            DropdownMenuItem(value: TimeBasis.zone, child: Text(l.basisZone)),
            DropdownMenuItem(value: TimeBasis.ut, child: Text(l.basisUt)),
            DropdownMenuItem(value: TimeBasis.lmt, child: Text(l.basisLmt)),
          ],
          onChanged: (v) => setState(() => _basis = v!),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _place,
          decoration: InputDecoration(labelText: l.fieldPlace, hintText: l.placeSearchHint, prefixIcon: const Icon(Icons.place_outlined)),
          onChanged: _search,
        ),
        for (final p in _suggestions)
          ListTile(dense: true, title: Text(p.name), subtitle: Text('${p.country} · ${p.lat.toStringAsFixed(2)}, ${p.lon.toStringAsFixed(2)} · ${p.zone}'), onTap: () => _pick(p)),
        if (_picked != null || _manual)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text('${_lat.text}, ${_lon.text} · ${_zone.text}', style: Theme.of(context).textTheme.bodySmall),
          ),
        SwitchListTile(contentPadding: EdgeInsets.zero, title: Text(l.manualCoords), value: _manual, onChanged: (v) => setState(() => _manual = v)),
        if (_manual) ...[
          TextField(controller: _lat, keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true), decoration: InputDecoration(labelText: l.fieldLat), onChanged: (_) => setState(() {})),
          TextField(controller: _lon, keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true), decoration: InputDecoration(labelText: l.fieldLon), onChanged: (_) => setState(() {})),
          TextField(controller: _zone, decoration: InputDecoration(labelText: l.fieldZone), onChanged: (_) => setState(() {})),
        ],
        const SizedBox(height: 16),
        DropdownButtonFormField<HouseSystem?>(
          initialValue: _system,
          decoration: InputDecoration(labelText: l.houseSystemField),
          items: [
            DropdownMenuItem(value: null, child: Text(l.houseSystemAuto)),
            for (final h in HouseSystem.values) DropdownMenuItem(value: h, child: Text(l.house(h))),
          ],
          onChanged: (v) => setState(() => _system = v),
        ),
        if (note != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(note, style: TextStyle(color: Theme.of(context).colorScheme.tertiary))),
        if (_error != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error))),
        const SizedBox(height: 24),
        FilledButton(onPressed: _save, child: Text(l.save)),
      ]),
    );
  }
}
