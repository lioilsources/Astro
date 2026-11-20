import 'chart.dart';

/// A place on Earth: where someone lives now (plan 10.2, owner decision 14),
/// used for planetary hours and later for elections (R7) and horary (R8).
class GeoLocation {
  /// Geographic latitude, degrees, north positive.
  final double lat;

  /// Geographic longitude, degrees, east positive.
  final double lon;
  final String? name;

  /// IANA zone, e.g. `Europe/Prague`; null when unknown.
  final String? zone;

  const GeoLocation({required this.lat, required this.lon, this.name, this.zone});

  /// The birth place of [b] (default residence).
  factory GeoLocation.ofBirth(BirthData b) => GeoLocation(lat: b.lat, lon: b.lon, name: b.placeName, zone: b.moment.zone);

  Map<String, Object?> toJson() => {'lat': lat, 'lon': lon, 'name': name, 'zone': zone};

  factory GeoLocation.fromJson(Map<String, Object?> j) => GeoLocation(
        lat: (j['lat'] as num).toDouble(),
        lon: (j['lon'] as num).toDouble(),
        name: j['name'] as String?,
        zone: j['zone'] as String?,
      );

  @override
  bool operator ==(Object other) =>
      other is GeoLocation && other.lat == lat && other.lon == lon && other.name == name && other.zone == zone;
  @override
  int get hashCode => Object.hash(lat, lon, name, zone);
  @override
  String toString() => '${name ?? ''} ($lat, $lon)';
}
