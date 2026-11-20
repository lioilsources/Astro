import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'l10n/app_localizations.dart';
import 'state.dart';
import 'ui/ask_screen.dart';
import 'ui/glossary_screen.dart';
import 'ui/onboarding_screen.dart';
import 'ui/people_screen.dart';
import 'ui/profiles_screen.dart';
import 'ui/settings_screen.dart';

ThemeData _theme(Brightness b) {
  final scheme = ColorScheme.fromSeed(seedColor: const Color(0xFF3D3A8C), brightness: b);
  return ThemeData(colorScheme: scheme, useMaterial3: true);
}

class AstroApp extends StatelessWidget {
  const AstroApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        onGenerateTitle: (c) => AppLocalizations.of(c).appTitle,
        theme: _theme(Brightness.light),
        darkTheme: _theme(Brightness.dark),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('cs'),
        home: const _Root(),
      );
}

class _Root extends ConsumerWidget {
  const _Root();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsProvider);
    return s.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('$e'))),
      data: (v) => v.onboardingDone ? const HomeScreen() : const OnboardingScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    const pages = [ProfilesScreen(), PeopleScreen(), AskScreen(), GlossaryScreen(), SettingsScreen()];
    return Scaffold(
      body: IndexedStack(index: _tab, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: [
          NavigationDestination(icon: const Icon(Icons.people_outline), label: l.navProfiles),
          NavigationDestination(icon: const Icon(Icons.star_outline), label: l.navPeople),
          NavigationDestination(icon: const Icon(Icons.help_outline), label: l.navAsk),
          NavigationDestination(icon: const Icon(Icons.menu_book_outlined), label: l.navGlossary),
          NavigationDestination(icon: const Icon(Icons.tune), label: l.navSettings),
        ],
      ),
    );
  }
}
