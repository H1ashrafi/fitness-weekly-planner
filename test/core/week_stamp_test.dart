import 'package:flutter_test/flutter_test.dart';
import 'package:hanimob2/core/time/week_stamp.dart';

import 'iso_week_ground_truth.dart';

void main() {
  group('WeekStamp.fromDate matches ISO-8601 ground truth', () {
    for (final IsoWeekCase sample in isoWeekGroundTruth) {
      test('${sample.date} resolves to ${sample.isoYear}-W${sample.isoWeek}', () {
        final WeekStamp stamp = WeekStamp.fromDate(DateTime.parse(sample.date));
        expect(stamp.isoYear, sample.isoYear);
        expect(stamp.isoWeek, sample.isoWeek);
      });
    }
  });

  group('WeekStamp.mondayMidnight anchors the reset boundary', () {
    for (final IsoWeekCase sample in isoWeekGroundTruth) {
      test('${sample.date} belongs to week starting ${sample.monday}', () {
        final WeekStamp stamp = WeekStamp.fromDate(DateTime.parse(sample.date));
        expect(stamp.mondayMidnight, DateTime.parse(sample.monday));
      });
    }
  });

  test('every instant of a week maps back to that same week', () {
    final WeekStamp week = WeekStamp.fromDate(DateTime(2026, 7, 15));
    for (int offsetHours = 0; offsetHours < 24 * 7; offsetHours++) {
      final DateTime moment =
          week.mondayMidnight.add(Duration(hours: offsetHours));
      expect(WeekStamp.fromDate(moment), week, reason: 'failed at $moment');
      expect(week.contains(moment), isTrue);
    }
  });

  test('the instant before Monday belongs to the previous week', () {
    final WeekStamp week = WeekStamp.fromDate(DateTime(2026, 7, 15));
    final DateTime lastInstantOfPreviousWeek =
        week.mondayMidnight.subtract(const Duration(microseconds: 1));
    expect(week.contains(lastInstantOfPreviousWeek), isFalse);
    expect(WeekStamp.fromDate(lastInstantOfPreviousWeek), week.previous);
  });

  test('exclusiveEnd is the next week Monday and is not contained', () {
    final WeekStamp week = WeekStamp.fromDate(DateTime(2026, 7, 15));
    expect(week.exclusiveEnd, week.next.mondayMidnight);
    expect(week.contains(week.exclusiveEnd), isFalse);
  });

  test('previous and next traverse 53-week year boundaries', () {
    final WeekStamp lastWeekOf2020 =
        WeekStamp.fromDate(DateTime(2020, 12, 31));
    expect(lastWeekOf2020.token, '2020-W53');
    expect(lastWeekOf2020.next.token, '2021-W01');
    expect(lastWeekOf2020.next.previous, lastWeekOf2020);
  });

  test('token round-trips through fromToken', () {
    for (final IsoWeekCase sample in isoWeekGroundTruth) {
      final WeekStamp stamp = WeekStamp.fromDate(DateTime.parse(sample.date));
      expect(WeekStamp.fromToken(stamp.token), stamp);
    }
  });

  test('token is zero-padded and sorts chronologically as text', () {
    final WeekStamp earlyWeek = WeekStamp.fromDate(DateTime(2026, 2, 3));
    expect(earlyWeek.token, '2026-W06');
    final List<String> tokens = <String>[
      WeekStamp.fromDate(DateTime(2026, 11, 2)).token,
      WeekStamp.fromDate(DateTime(2026, 2, 3)).token,
      WeekStamp.fromDate(DateTime(2025, 6, 9)).token,
    ]..sort();
    expect(tokens, <String>['2025-W24', '2026-W06', '2026-W45']);
  });

  test('rejects malformed tokens', () {
    expect(() => WeekStamp.fromToken('2026'), throwsFormatException);
    expect(() => WeekStamp.fromToken('2026-Wxx'), throwsFormatException);
  });
}
