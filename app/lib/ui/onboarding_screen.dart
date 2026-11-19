import 'package:astro_core/content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../state.dart';

/// First launch: say that the reading contains shadow sides and hard topics,
/// offer the gentle mode (plan 5.1). Default stays "show everything".
class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    Future<void> done(bool gentle) => ref.read(settingsProvider.notifier).change(
          (s) => s.copyWith(onboardingDone: true, hiddenTopics: gentle ? hardTopics.toSet() : const {}),
        );
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 24),
            Text(l.onboardingTitle, style: t.headlineMedium),
            const SizedBox(height: 16),
            Text(l.onboardingBody, style: t.bodyLarge),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(l.gentleMode, style: t.titleMedium),
                  const SizedBox(height: 8),
                  Text('„${l.onboardingGentle}“', style: t.bodyMedium?.copyWith(fontStyle: FontStyle.italic)),
                  const SizedBox(height: 8),
                  Text(l.onboardingHint, style: t.bodySmall),
                ]),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(onPressed: () => done(false), child: Text(l.onboardingShowAll)),
            const SizedBox(height: 8),
            OutlinedButton(onPressed: () => done(true), child: Text(l.onboardingUseGentle)),
          ],
        ),
      ),
    );
  }
}
