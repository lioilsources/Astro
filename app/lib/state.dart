import 'package:astro_core/astro_core.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/content_repository.dart';
import 'data/places.dart';
import 'data/profile.dart';
import 'data/profile_store.dart';
import 'data/settings.dart';
import 'logic/filter.dart';

final contentProvider = FutureProvider<ContentRepository>((ref) => ContentRepository.load(rootBundle));
final placesProvider = FutureProvider<PlaceIndex>((ref) => PlaceIndex.load(rootBundle));
final profileStoreProvider = Provider<ProfileStore>((ref) => ProfileStore());

class SettingsNotifier extends AsyncNotifier<AppSettings> {
  @override
  Future<AppSettings> build() => AppSettings.load();

  Future<void> change(AppSettings Function(AppSettings) f) async {
    final next = f(state.value ?? const AppSettings());
    state = AsyncData(next);
    await next.save();
  }
}

final settingsProvider = AsyncNotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);

final filterProvider = Provider<ContentFilter>((ref) {
  final s = ref.watch(settingsProvider).value ?? const AppSettings();
  return ContentFilter(hiddenTopics: s.hiddenTopics, hideShadow: s.hideShadow);
});

class ProfilesNotifier extends AsyncNotifier<List<Profile>> {
  @override
  Future<List<Profile>> build() => ref.read(profileStoreProvider).load();

  Future<void> _save(List<Profile> list) async {
    state = AsyncData(list);
    await ref.read(profileStoreProvider).save(list);
  }

  Future<void> upsert(Profile p) async {
    final list = [...?state.value];
    final i = list.indexWhere((x) => x.id == p.id);
    if (i >= 0) {
      list[i] = p;
    } else {
      list.add(p);
    }
    await _save(list);
  }

  Future<void> remove(String id) => _save([...?state.value?.where((p) => p.id != id)]);
}

final profilesProvider = AsyncNotifierProvider<ProfilesNotifier, List<Profile>>(ProfilesNotifier.new);

/// Natal chart of a profile under the current settings.
final chartProvider = Provider.family<Chart, Profile>((ref, p) {
  final s = ref.watch(settingsProvider).value ?? const AppSettings();
  return Chart.compute(p.birth, options: s.chartOptions(p.houseSystem));
});
