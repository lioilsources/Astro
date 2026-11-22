import 'package:astro_core/astro_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/pairs.dart';

final pairStoreProvider = Provider<PairStore>((ref) => PairStore());

/// Saved pairs (plan R9 6.1). Only saved profiles take part, never catalog people.
class PairsNotifier extends AsyncNotifier<List<Pair>> {
  @override
  Future<List<Pair>> build() => ref.read(pairStoreProvider).load();

  Future<void> _save(List<Pair> list) async {
    state = AsyncData(list);
    await ref.read(pairStoreProvider).save(list);
  }

  /// Adds the pair, or updates the relationship of the same two people.
  Future<Pair> add(String firstId, String secondId, Relationship relationship) async {
    final list = [...await future];
    final i = list.indexWhere((p) => (p.firstId == firstId && p.secondId == secondId) || (p.firstId == secondId && p.secondId == firstId));
    final pair = Pair(
      id: i >= 0 ? list[i].id : '${DateTime.now().microsecondsSinceEpoch}',
      firstId: firstId,
      secondId: secondId,
      relationship: relationship,
    );
    if (i >= 0) {
      list[i] = pair;
    } else {
      list.add(pair);
    }
    await _save(list);
    return pair;
  }

  Future<void> remove(String id) async => _save([...(await future).where((p) => p.id != id)]);

  /// A deleted profile takes its pairs with it.
  Future<void> removeProfile(String profileId) async => _save([...(await future).where((p) => !p.involves(profileId))]);
}

final pairsProvider = AsyncNotifierProvider<PairsNotifier, List<Pair>>(PairsNotifier.new);
