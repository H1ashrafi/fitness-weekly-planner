import 'package:flutter/foundation.dart';

@immutable
final class WeekStamp implements Comparable<WeekStamp> {
  const WeekStamp({required this.isoYear, required this.isoWeek})
      : assert(isoWeek >= 1 && isoWeek <= 53, 'isoWeek must fall within 1..53');

  factory WeekStamp.fromDate(DateTime moment) {
    final DateTime civilDay = DateTime.utc(moment.year, moment.month, moment.day);
    final DateTime thursdayOfWeek =
        civilDay.add(Duration(days: 4 - civilDay.weekday));
    final DateTime firstDayOfIsoYear = DateTime.utc(thursdayOfWeek.year, 1, 1);
    final int dayOrdinal = thursdayOfWeek.difference(firstDayOfIsoYear).inDays + 1;
    return WeekStamp(
      isoYear: thursdayOfWeek.year,
      isoWeek: ((dayOrdinal - 1) ~/ 7) + 1,
    );
  }

  factory WeekStamp.fromToken(String token) {
    final List<String> parts = token.split('-W');
    if (parts.length != 2) {
      throw FormatException('WeekStamp token must look like 2026-W07', token);
    }
    final int? year = int.tryParse(parts.first);
    final int? week = int.tryParse(parts.last);
    if (year == null || week == null) {
      throw FormatException('WeekStamp token carries non-numeric parts', token);
    }
    return WeekStamp(isoYear: year, isoWeek: week);
  }

  final int isoYear;
  final int isoWeek;

  String get token => '$isoYear-W${isoWeek.toString().padLeft(2, '0')}';

  DateTime get _mondayAsUtcCivilDay {
    final DateTime fourthOfJanuary = DateTime.utc(isoYear, 1, 4);
    final DateTime mondayOfFirstWeek =
        fourthOfJanuary.subtract(Duration(days: fourthOfJanuary.weekday - 1));
    return mondayOfFirstWeek.add(Duration(days: (isoWeek - 1) * 7));
  }

  DateTime get mondayMidnight {
    final DateTime monday = _mondayAsUtcCivilDay;
    return DateTime(monday.year, monday.month, monday.day);
  }

  DateTime get exclusiveEnd {
    final DateTime monday = _mondayAsUtcCivilDay;
    return DateTime(monday.year, monday.month, monday.day + 7);
  }

  bool contains(DateTime moment) =>
      !moment.isBefore(mondayMidnight) && moment.isBefore(exclusiveEnd);

  WeekStamp get previous {
    final DateTime monday = _mondayAsUtcCivilDay;
    return WeekStamp.fromDate(
      DateTime.utc(monday.year, monday.month, monday.day - 3),
    );
  }

  WeekStamp get next {
    final DateTime monday = _mondayAsUtcCivilDay;
    return WeekStamp.fromDate(
      DateTime.utc(monday.year, monday.month, monday.day + 10),
    );
  }

  @override
  int compareTo(WeekStamp other) => isoYear != other.isoYear
      ? isoYear.compareTo(other.isoYear)
      : isoWeek.compareTo(other.isoWeek);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WeekStamp && other.isoYear == isoYear && other.isoWeek == isoWeek;

  @override
  int get hashCode => Object.hash(isoYear, isoWeek);

  @override
  String toString() => token;
}
