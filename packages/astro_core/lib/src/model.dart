import 'angles.dart';

enum Sign {
  aries,
  taurus,
  gemini,
  cancer,
  leo,
  virgo,
  libra,
  scorpio,
  sagittarius,
  capricorn,
  aquarius,
  pisces;

  static Sign ofLongitude(double lon) => Sign.values[norm360(lon) ~/ 30];

  Element get element => Element.values[index % 4];
  Modality get modality => Modality.values[index % 3];
  Sign get opposite => Sign.values[(index + 6) % 12];
}

enum Element { fire, earth, air, water }

enum Modality { cardinal, fixed, mutable }

enum Body {
  sun,
  moon,
  mercury,
  venus,
  mars,
  jupiter,
  saturn,
  uranus,
  neptune,
  pluto,
  meanNode,
  trueNode;

  bool get isPlanet => index <= Body.pluto.index;
  bool get isLuminary => this == sun || this == moon;
  bool get isNode => this == meanNode || this == trueNode;

  /// The ten planets used for aspects, houses and transits.
  static const planets = [sun, moon, mercury, venus, mars, jupiter, saturn, uranus, neptune, pluto];

  /// Traditional seven (horary, planetary hours).
  static const traditional = [sun, moon, mercury, venus, mars, jupiter, saturn];
}

enum Angle { asc, mc }

/// A point an aspect can be made to: a body or an angle.
class ChartPoint {
  final Body? body;
  final Angle? angle;
  const ChartPoint.body(Body this.body) : angle = null;
  const ChartPoint.angle(Angle this.angle) : body = null;

  String get id => body?.name ?? angle!.name;
  bool get isAngle => angle != null;

  /// Sun, Moon, ASC, MC — "personal" points for transit strength.
  bool get isPersonal => isAngle || (body?.isLuminary ?? false);

  @override
  bool operator ==(Object other) => other is ChartPoint && other.body == body && other.angle == angle;
  @override
  int get hashCode => Object.hash(body, angle);
  @override
  String toString() => id;
}

/// Apparent geocentric ecliptic position of date.
class EclipticPosition {
  /// Longitude in degrees, 0..360.
  final double lon;

  /// Latitude in degrees.
  final double lat;

  /// Daily motion in longitude, degrees per day (negative = retrograde).
  final double speed;

  /// Distance in AU (Moon: AU as well), 0 when not meaningful (nodes).
  final double distance;

  const EclipticPosition({required this.lon, required this.lat, required this.speed, this.distance = 0});

  Sign get sign => Sign.ofLongitude(lon);
  bool get retrograde => speed < 0;
  double get degreeInSign => norm360(lon) % 30;
}
