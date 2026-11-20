import 'package:astro_core/astro_core.dart';
import 'package:astro_core/content.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App-wide settings. Not sensitive, kept in shared preferences.
class AppSettings {
  /// Hard topics the user chose not to see (plan 5.1). Empty = show everything.
  final Set<String> hiddenTopics;
  final bool hideShadow;
  final bool onboardingDone;
  final HouseSystem? defaultHouseSystem;
  final bool tightOrbs;
  final bool trueNode;

  /// Void-of-course Moon from the seven traditional planets only (plan 10.2).
  final bool vocTraditional;

  const AppSettings({
    this.hiddenTopics = const {},
    this.hideShadow = false,
    this.onboardingDone = false,
    this.defaultHouseSystem,
    this.tightOrbs = false,
    this.trueNode = false,
    this.vocTraditional = false,
  });

  bool get gentle => hiddenTopics.length == hardTopics.length;

  AppSettings copyWith({
    Set<String>? hiddenTopics,
    bool? hideShadow,
    bool? onboardingDone,
    HouseSystem? defaultHouseSystem,
    bool clearDefaultHouseSystem = false,
    bool? tightOrbs,
    bool? trueNode,
    bool? vocTraditional,
  }) =>
      AppSettings(
        hiddenTopics: hiddenTopics ?? this.hiddenTopics,
        hideShadow: hideShadow ?? this.hideShadow,
        onboardingDone: onboardingDone ?? this.onboardingDone,
        defaultHouseSystem: clearDefaultHouseSystem ? null : (defaultHouseSystem ?? this.defaultHouseSystem),
        tightOrbs: tightOrbs ?? this.tightOrbs,
        trueNode: trueNode ?? this.trueNode,
        vocTraditional: vocTraditional ?? this.vocTraditional,
      );

  ChartOptions chartOptions(HouseSystem? profileSystem) => ChartOptions(
        houseSystem: profileSystem ?? defaultHouseSystem,
        orbs: tightOrbs ? OrbConfig.tight : const OrbConfig(),
        node: trueNode ? NodeKind.trueNode : NodeKind.mean,
      );

  static Future<AppSettings> load() async {
    final p = await SharedPreferences.getInstance();
    final hs = p.getString('defaultHouseSystem');
    return AppSettings(
      hiddenTopics: (p.getStringList('hiddenTopics') ?? const []).toSet(),
      hideShadow: p.getBool('hideShadow') ?? false,
      onboardingDone: p.getBool('onboardingDone') ?? false,
      defaultHouseSystem: hs == null ? null : HouseSystem.values.byName(hs),
      tightOrbs: p.getBool('tightOrbs') ?? false,
      trueNode: p.getBool('trueNode') ?? false,
      vocTraditional: p.getBool('vocTraditional') ?? false,
    );
  }

  Future<void> save() async {
    final p = await SharedPreferences.getInstance();
    await p.setStringList('hiddenTopics', hiddenTopics.toList()..sort());
    await p.setBool('hideShadow', hideShadow);
    await p.setBool('onboardingDone', onboardingDone);
    if (defaultHouseSystem == null) {
      await p.remove('defaultHouseSystem');
    } else {
      await p.setString('defaultHouseSystem', defaultHouseSystem!.name);
    }
    await p.setBool('tightOrbs', tightOrbs);
    await p.setBool('trueNode', trueNode);
    await p.setBool('vocTraditional', vocTraditional);
  }
}
