import 'package:astro_core/astro_core.dart';

/// A personal event stored with a profile (query B, plan 3.5).
class LifeEvent {
  final String id;
  final double jdUt;
  final String label;
  const LifeEvent(this.id, this.jdUt, this.label);
  Map<String, Object?> toJson() => {'id': id, 'jd': jdUt, 'label': label};
  factory LifeEvent.fromJson(Map<String, Object?> j) =>
      LifeEvent(j['id'] as String, (j['jd'] as num).toDouble(), j['label'] as String);
}

class Profile {
  final String id;
  final String name;
  final BirthData birth;

  /// Null = automatic by birth latitude.
  final HouseSystem? houseSystem;
  final List<LifeEvent> events;

  /// Catalog person id when opened from the people catalog (read-only).
  final String? catalogId;

  /// Rodden grade of the birth time (AA, A, B, C, X) and source note for catalog people.
  final String? catalogReliability;
  final String? catalogSource;

  /// Where the person lives now (planetary hours, plan 10.2). Null = the birth place.
  final GeoLocation? residence;

  const Profile({
    required this.id,
    required this.name,
    required this.birth,
    this.houseSystem,
    this.events = const [],
    this.catalogId,
    this.catalogReliability,
    this.catalogSource,
    this.residence,
  });

  /// Residence, defaulting to the birth place (owner decision 14).
  GeoLocation get residencePlace => residence ?? GeoLocation.ofBirth(birth);

  Profile copyWith({
    String? name,
    BirthData? birth,
    HouseSystem? houseSystem,
    bool clearHouseSystem = false,
    List<LifeEvent>? events,
    GeoLocation? residence,
    bool clearResidence = false,
  }) =>
      Profile(
        id: id,
        name: name ?? this.name,
        birth: birth ?? this.birth,
        houseSystem: clearHouseSystem ? null : (houseSystem ?? this.houseSystem),
        events: events ?? this.events,
        catalogId: catalogId,
        catalogReliability: catalogReliability,
        catalogSource: catalogSource,
        residence: clearResidence ? null : (residence ?? this.residence),
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'name': name,
        'birth': birth.toJson(),
        'houseSystem': houseSystem?.name,
        'events': [for (final e in events) e.toJson()],
        if (residence != null) 'residence': residence!.toJson(),
      };

  factory Profile.fromJson(Map<String, Object?> j) => Profile(
        id: j['id'] as String,
        name: j['name'] as String,
        birth: BirthData.fromJson((j['birth'] as Map).cast<String, Object?>()),
        houseSystem: j['houseSystem'] == null ? null : HouseSystem.values.byName(j['houseSystem'] as String),
        events: [for (final e in (j['events'] as List? ?? const [])) LifeEvent.fromJson((e as Map).cast<String, Object?>())],
        // Profiles saved before R2 have no residence: they fall back to the birth place.
        residence: j['residence'] == null ? null : GeoLocation.fromJson((j['residence'] as Map).cast<String, Object?>()),
      );
}
