import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/reminder.dart';
import '../../journal_state.dart';
import '../../l10n/app_localizations.dart';
import '../format.dart';

/// Opt-in evening reminder of the prediction journal (settings screen).
class ReminderTile extends ConsumerWidget {
  const ReminderTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final s = ref.watch(reminderProvider).value ?? const ReminderSettings();
    final time = '${s.minutes ~/ 60}:${two(s.minutes % 60)}';

    Future<void> apply(ReminderSettings next) async {
      final ok = await ref.read(reminderProvider.notifier).change(next, title: l.journalReminderTitle, body: l.journalReminderBody);
      if (!ok && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.journalReminderDenied)));
      }
    }

    return SwitchListTile(
      title: Text(l.journalReminder),
      subtitle: InkWell(
        onTap: () async {
          final picked = await showTimePicker(context: context, initialTime: TimeOfDay(hour: s.minutes ~/ 60, minute: s.minutes % 60));
          if (picked != null) await apply(s.copyWith(minutes: picked.hour * 60 + picked.minute));
        },
        child: Text(l.journalReminderDesc(time)),
      ),
      value: s.enabled,
      onChanged: (v) => apply(s.copyWith(enabled: v)),
    );
  }
}
