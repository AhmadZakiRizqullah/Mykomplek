// lib/utils/date_helper.dart
import 'package:intl/intl.dart';

class DateHelper {
  // Nama hari dalam Bahasa Indonesia
  static const Map<int, String> _dayNames = {
    1: 'Senin',
    2: 'Selasa',
    3: 'Rabu',
    4: 'Kamis',
    5: 'Jumat',
    6: 'Sabtu',
    7: 'Minggu',
  };

  // Nama bulan dalam Bahasa Indonesia
  static const Map<int, String> _monthNames = {
    1: 'Januari',
    2: 'Februari',
    3: 'Maret',
    4: 'April',
    5: 'Mei',
    6: 'Juni',
    7: 'Juli',
    8: 'Agustus',
    9: 'September',
    10: 'Oktober',
    11: 'November',
    12: 'Desember',
  };

  /// Format: Senin, 30 Desember 2024
  static String formatFullDate(DateTime date) {
    final dayName = _dayNames[date.weekday];
    final monthName = _monthNames[date.month];
    return '$dayName, ${date.day} $monthName ${date.year}';
  }

  /// Format: 30 Desember 2024
  static String formatDate(DateTime date) {
    final monthName = _monthNames[date.month];
    return '${date.day} $monthName ${date.year}';
  }

  /// Format: 14:30
  static String formatTime(DateTime date) {
    return DateFormat('HH:mm').format(date);
  }

  /// Format: 30/12/2024 14:30
  static String formatDateTime(DateTime date) {
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  /// Format: 2024-12-30 (for API)
  static String formatDateForApi(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }
}
