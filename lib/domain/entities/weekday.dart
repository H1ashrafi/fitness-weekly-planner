enum Weekday {
  monday(isoIndex: 1, fullName: 'Monday', initial: 'M'),
  tuesday(isoIndex: 2, fullName: 'Tuesday', initial: 'T'),
  wednesday(isoIndex: 3, fullName: 'Wednesday', initial: 'W'),
  thursday(isoIndex: 4, fullName: 'Thursday', initial: 'T'),
  friday(isoIndex: 5, fullName: 'Friday', initial: 'F'),
  saturday(isoIndex: 6, fullName: 'Saturday', initial: 'S'),
  sunday(isoIndex: 7, fullName: 'Sunday', initial: 'S');

  const Weekday({
    required this.isoIndex,
    required this.fullName,
    required this.initial,
  });

  final int isoIndex;
  final String fullName;
  final String initial;

  static Weekday fromIsoIndex(int index) => switch (index) {
        1 => Weekday.monday,
        2 => Weekday.tuesday,
        3 => Weekday.wednesday,
        4 => Weekday.thursday,
        5 => Weekday.friday,
        6 => Weekday.saturday,
        7 => Weekday.sunday,
        _ => throw RangeError.range(index, 1, 7, 'isoIndex'),
      };

  static Weekday of(DateTime moment) => fromIsoIndex(moment.weekday);

  String get abbreviation => fullName.substring(0, 3);
}
