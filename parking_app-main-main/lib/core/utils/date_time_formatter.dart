import 'package:intl/intl.dart';

class DateTimeFormatter {
  static String formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  static String formatTime(DateTime date) {
    return DateFormat('hh:mm a').format(date);
  }

  static String formatDateTime(DateTime date) {
    return DateFormat('yyyy-MM-dd hh:mm a').format(date);
  }

  static DateTime parseDate(String date) {
    return DateFormat('yyyy-MM-dd').parse(date);
  }

  static DateTime parseTime(String time) {
    return DateFormat('hh:mm a').parse(time);
  }
}
