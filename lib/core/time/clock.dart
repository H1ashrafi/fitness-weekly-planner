import '../../domain/entities/weekday.dart';
import 'week_stamp.dart';

abstract interface class Clock {
  DateTime now();
}

final class SystemClock implements Clock {
  const SystemClock();

  @override
  DateTime now() => DateTime.now();
}

final class FixedClock implements Clock {
  const FixedClock(this._instant);

  final DateTime _instant;

  @override
  DateTime now() => _instant;
}

extension ClockCalendar on Clock {
  WeekStamp get currentWeek => WeekStamp.fromDate(now());

  Weekday get today => Weekday.of(now());

  DateTime get startOfToday {
    final DateTime moment = now();
    return DateTime(moment.year, moment.month, moment.day);
  }

  Duration get untilNextWeek => currentWeek.exclusiveEnd.difference(now());
}
