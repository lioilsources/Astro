import 'package:astro_core/astro_core.dart';
import 'package:test/test.dart';

LocalMoment zoned(int y, int m, int d, int h, int mi, String zone) =>
    LocalMoment(year: y, month: m, day: d, hour: h, minute: mi, zone: zone);

void main() {
  test('Julian Day for both calendars', () {
    expect(julianDay(2000, 1, 1, 12), 2451545.0);
    expect(julianDay(1582, 10, 4, 0, calendar: CalendarKind.julian), 2299159.5);
    expect(julianDay(1582, 10, 15, 0), 2299160.5);
    expect(julianDay(1066, 10, 14, 0, calendar: CalendarKind.julian), 2110700.5);
    final c = calendarFromJd(2451545.0);
    expect([c.year, c.month, c.day], [2000, 1, 1.5]);
    expect(defaultCalendar(1500, 1, 1), CalendarKind.julian);
    expect(defaultCalendar(1582, 10, 15), CalendarKind.gregorian);
  });

  test('Czech summer and winter time', () {
    expect(resolveMoment(zoned(1980, 9, 20, 12, 0, 'Europe/Prague'), 14.42).offsetHours, 2);
    expect(resolveMoment(zoned(1980, 12, 10, 12, 0, 'Europe/Prague'), 14.42).offsetHours, 1);
    expect(resolveMoment(zoned(2021, 6, 1, 12, 0, 'Europe/Prague'), 14.42).abbreviation, 'CEST');
    final r = resolveMoment(zoned(2000, 1, 1, 13, 0, 'Europe/Prague'), 14.42);
    expect(r.jdUt, closeTo(2451545.0, 1e-6));
  });

  test('western and southern hemisphere zones', () {
    expect(resolveMoment(zoned(1990, 7, 4, 12, 0, 'America/New_York'), -74).offsetHours, -4);
    expect(resolveMoment(zoned(2000, 1, 1, 12, 0, 'Australia/Sydney'), 151.2).offsetHours, 11);
    // Date change: 01:00 in Sydney is the previous UT day.
    final r = resolveMoment(zoned(2000, 1, 1, 1, 0, 'Australia/Sydney'), 151.2);
    expect(calendarFromJd(r.jdUt).day.floor(), 31);
  });

  test('before zone time → local mean time of the birth longitude', () {
    final r = resolveMoment(zoned(1850, 1, 1, 12, 0, 'Europe/Prague'), 15);
    expect(r.basisUsed, TimeBasis.lmt);
    expect(r.jdUt, closeTo(julianDay(1850, 1, 1, 11), 1e-9));
    final j = resolveMoment(
        const LocalMoment(year: 1500, month: 3, day: 1, hour: 6, minute: 0, calendar: CalendarKind.julian, zone: 'Europe/Prague'), 15);
    expect(j.basisUsed, TimeBasis.lmt);
  });

  test('DST change flags ambiguous and skipped times', () {
    expect(resolveMoment(zoned(2021, 10, 31, 2, 30, 'Europe/Prague'), 14.42).dstAmbiguous, isTrue);
    expect(resolveMoment(zoned(2021, 3, 28, 2, 30, 'Europe/Prague'), 14.42).dstAmbiguous, isTrue);
    expect(resolveMoment(zoned(2021, 7, 1, 2, 30, 'Europe/Prague'), 14.42).dstAmbiguous, isFalse);
  });

  test('UT round trip to zone', () {
    final t = utToZone(2451545.0, 'Europe/Prague');
    expect([t.hour, t.minute], [13, 0]);
  });
}
