import 'package:intl/intl.dart';

class DateFmt {
  static final _shortDate = DateFormat('MMM d, y');
  static final _longDate = DateFormat('EEEE, MMMM d, y');
  static final _time = DateFormat('h:mm a');
  static final _shortDateTime = DateFormat('MMM d, h:mm a');
  static final _dayMonth = DateFormat('d MMM');

  static String shortDate(DateTime d) => _shortDate.format(d);
  static String longDate(DateTime d) => _longDate.format(d);
  static String time(DateTime d) => _time.format(d);
  static String shortDateTime(DateTime d) => _shortDateTime.format(d);
  static String dayMonth(DateTime d) => _dayMonth.format(d);

  static String relative(DateTime d) {
    final now = DateTime.now();
    final diff = d.difference(now);
    if (diff.isNegative) {
      final past = now.difference(d);
      if (past.inMinutes < 1) return 'just now';
      if (past.inMinutes < 60) return '${past.inMinutes}m ago';
      if (past.inHours < 24) return '${past.inHours}h ago';
      if (past.inDays < 7) return '${past.inDays}d ago';
      return shortDate(d);
    }
    if (diff.inMinutes < 60) return 'in ${diff.inMinutes}m';
    if (diff.inHours < 24) return 'in ${diff.inHours}h';
    if (diff.inDays < 7) return 'in ${diff.inDays}d';
    return shortDate(d);
  }

  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
