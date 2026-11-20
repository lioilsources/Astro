import 'dart:math' as math;

import 'package:astro_core/astro_core.dart';
import 'package:flutter/material.dart';

import 'format.dart';

/// Zodiac wheel: signs, house cusps, planets (spread when clustered), aspect lines.
/// ASC sits at 9 o'clock; without a birth time 0° Aries does.
class ChartWheel extends StatelessWidget {
  final Chart chart;

  /// Optional outer ring (transits or a second person).
  final Map<Body, double>? outer;

  /// Fixed-star longitudes to mark on the outer rim; [starHits] are the ids in conjunction.
  final Map<FixedStar, double>? stars;
  final Set<String> starHits;
  const ChartWheel(this.chart, {super.key, this.outer, this.stars, this.starHits = const {}});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AspectRatio(
      aspectRatio: 1,
      child: CustomPaint(painter: WheelPainter(chart, scheme, outer: outer, stars: stars, starHits: starHits, textStyle: Theme.of(context).textTheme.bodySmall ?? const TextStyle())),
    );
  }
}

class WheelPainter extends CustomPainter {
  final Chart chart;
  final ColorScheme scheme;
  final Map<Body, double>? outer;
  final TextStyle textStyle;
  final Map<FixedStar, double>? stars;
  final Set<String> starHits;
  WheelPainter(this.chart, this.scheme, {this.outer, this.stars, this.starHits = const {}, this.textStyle = const TextStyle()});

  static const _elementColors = [Color(0xFFD9534F), Color(0xFF5B8C3A), Color(0xFFD4A82A), Color(0xFF3E7CB1)];

  /// Spreads longitudes so neighbours are at least [minGap] degrees apart for drawing.
  static List<double> spread(List<double> lons, double minGap) {
    if (lons.length < 2) return [...lons];
    final idx = List<int>.generate(lons.length, (i) => i)..sort((a, b) => lons[a].compareTo(lons[b]));
    final pos = [for (final i in idx) lons[i]];
    for (var pass = 0; pass < 30; pass++) {
      var moved = false;
      for (var k = 0; k < pos.length; k++) {
        final n = (k + 1) % pos.length;
        final gap = norm360(pos[n] - pos[k]);
        if (gap < minGap && pos.length * minGap < 360) {
          final push = (minGap - gap) / 2;
          pos[k] -= push;
          pos[n] += push;
          moved = true;
        }
      }
      if (!moved) break;
    }
    final out = List<double>.filled(lons.length, 0);
    for (var k = 0; k < idx.length; k++) {
      out[idx[k]] = norm360(pos[k]);
    }
    return out;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2 - 4;
    final rot = chart.asc ?? 0;
    Offset at(double lon, double radius) {
      final a = (180 + (lon - rot)) * math.pi / 180;
      return c + Offset(radius * math.cos(a), -radius * math.sin(a));
    }

    final line = Paint()
      ..style = PaintingStyle.stroke
      ..color = scheme.outline
      ..strokeWidth = 1;
    final rSignOut = r, rSignIn = r * 0.84, rHouse = r * 0.40, rPlanet = r * 0.70;

    // Sign ring with element tint.
    for (var i = 0; i < 12; i++) {
      final path = Path();
      final a0 = (180 + (i * 30 - rot)) * math.pi / 180;
      path.addArc(Rect.fromCircle(center: c, radius: (rSignOut + rSignIn) / 2), -a0, -30 * math.pi / 180);
      canvas.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = rSignOut - rSignIn
            ..color = _elementColors[i % 4].withValues(alpha: 0.16));
      canvas.drawLine(at(i * 30.0, rSignIn), at(i * 30.0, rSignOut), line);
      _text(canvas, signGlyph[i], at(i * 30 + 15, (rSignOut + rSignIn) / 2), r * 0.085, _elementColors[i % 4]);
    }
    canvas.drawCircle(c, rSignOut, line);
    canvas.drawCircle(c, rSignIn, line);
    canvas.drawCircle(c, rHouse, line);

    // House cusps; angles thicker.
    final cusps = chart.houses?.cusps;
    if (cusps != null) {
      for (var i = 0; i < 12; i++) {
        final angle = i % 3 == 0;
        canvas.drawLine(at(cusps[i], rHouse), at(cusps[i], rSignIn),
            Paint()
              ..color = angle ? scheme.onSurface : scheme.outlineVariant
              ..strokeWidth = angle ? 2 : 1);
        final mid = cusps[i] + norm360(cusps[(i + 1) % 12] - cusps[i]) / 2;
        _text(canvas, '${i + 1}', at(mid, rHouse + r * 0.06), r * 0.045, scheme.onSurfaceVariant, glyph: false);
      }
      _text(canvas, 'AC', at(chart.asc!, rSignIn - r * 0.05), r * 0.045, scheme.primary, glyph: false);
      _text(canvas, 'MC', at(chart.mc!, rSignIn - r * 0.05), r * 0.045, scheme.primary, glyph: false);
    }

    // Aspect lines inside the house circle.
    for (final a in chart.aspects) {
      final la = chart.lonOf(a.a), lb = chart.lonOf(a.b);
      if (la == null || lb == null || a.a.isAngle || a.b.isAngle || a.type == AspectType.conjunction) continue;
      final color = switch (a.type.quality) {
        AspectQuality.harmonious => const Color(0xFF3E7CB1),
        AspectQuality.tense => const Color(0xFFD9534F),
        AspectQuality.conjunction => scheme.outline,
      };
      canvas.drawLine(at(la, rHouse), at(lb, rHouse),
          Paint()
            ..color = color.withValues(alpha: 0.35 + 0.5 * a.exactness)
            ..strokeWidth = 1.2);
    }

    // Planets, spread when clustered, with a tick at the true position.
    final bodies = chart.bodies;
    final lons = [for (final b in bodies) chart.positions[b]!.lon];
    final shown = spread(lons, 9);
    for (var i = 0; i < bodies.length; i++) {
      canvas.drawLine(at(lons[i], rSignIn), at(lons[i], rSignIn - r * 0.04), Paint()..color = scheme.onSurface);
      final p = chart.positions[bodies[i]]!;
      _text(canvas, bodyGlyph[bodies[i]]!, at(shown[i], rPlanet), r * 0.08, p.retrograde ? scheme.error : scheme.onSurface);
    }

    // Fixed stars: dots on the outer rim, larger and highlighted when in conjunction.
    final st = stars;
    if (st != null) {
      st.forEach((s, lon) {
        final hit = starHits.contains(s.id);
        canvas.drawLine(at(lon, rSignOut), at(lon, rSignOut - r * (hit ? 0.05 : 0.025)),
            Paint()
              ..color = hit ? scheme.error : scheme.outline
              ..strokeWidth = hit ? 1.5 : 1);
        canvas.drawCircle(at(lon, rSignOut), hit ? r * 0.018 : r * 0.008, Paint()..color = hit ? scheme.error : scheme.outline);
      });
    }

    final o = outer;
    if (o != null) {
      final ob = o.keys.toList();
      final olons = [for (final b in ob) o[b]!];
      final oshown = spread(olons, 8);
      for (var i = 0; i < ob.length; i++) {
        canvas.drawLine(at(olons[i], rSignOut), at(olons[i], rSignOut - r * 0.03), Paint()..color = scheme.tertiary);
        _text(canvas, bodyGlyph[ob[i]]!, at(oshown[i], rSignIn + (rSignOut - rSignIn) * 0.25), r * 0.05, scheme.tertiary);
      }
    }
  }

  void _text(Canvas canvas, String s, Offset center, double size, Color color, {bool glyph = true}) {
    final tp = TextPainter(
      text: TextSpan(text: s, style: (glyph ? glyphStyle : textStyle).copyWith(fontSize: size, color: color, height: 1)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(WheelPainter old) => old.chart != chart || old.scheme != scheme || old.outer != outer || old.stars != stars || old.starHits != starHits;
}
