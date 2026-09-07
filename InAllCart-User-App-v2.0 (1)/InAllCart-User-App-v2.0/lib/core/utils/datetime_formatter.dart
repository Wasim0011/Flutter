import 'package:intl/intl.dart';
import '../../features/app_config/domain/entities/app_config.dart';

class DateTimeFormatter {
  final TimezoneConfig config;

  DateTimeFormatter(this.config);

  /// Format date according to configured format
  String formatDate(DateTime dateTime) {
    // Convert PHP date format to Dart DateFormat pattern
    String pattern = _convertPhpToDartFormat(config.dateFormat);
    return DateFormat(pattern).format(dateTime);
  }

  /// Format time according to configured format
  String formatTime(DateTime dateTime) {
    if (config.timeFormat == '24') {
      return DateFormat('HH:mm').format(dateTime);
    } else {
      return DateFormat('h:mm a').format(dateTime);
    }
  }

  /// Format date and time
  String formatDateTime(DateTime dateTime) {
    return '${formatDate(dateTime)} ${formatTime(dateTime)}';
  }

  /// Format relative time (e.g., "2 hours ago")
  String formatRelative(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else {
      return 'Just now';
    }
  }

  /// Format for order history (e.g., "Today, 2:30 PM" or "Jan 15, 2:30 PM")
  String formatOrderDate(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (dateOnly == today) {
      return 'Today, ${formatTime(dateTime)}';
    } else if (dateOnly == yesterday) {
      return 'Yesterday, ${formatTime(dateTime)}';
    } else if (now.difference(dateTime).inDays < 7) {
      return '${DateFormat('EEEE').format(dateTime)}, ${formatTime(dateTime)}';
    } else {
      return '${DateFormat('MMM d').format(dateTime)}, ${formatTime(dateTime)}';
    }
  }

  /// Convert PHP date format to Dart DateFormat pattern
  String _convertPhpToDartFormat(String phpFormat) {
    // Common PHP to Dart format conversions
    final conversions = {
      'd/m/Y': 'dd/MM/yyyy',
      'm/d/Y': 'MM/dd/yyyy',
      'Y-m-d': 'yyyy-MM-dd',
      'd M, Y': 'dd MMM, yyyy',
      'M d, Y': 'MMM dd, yyyy',
      'd-m-Y': 'dd-MM-yyyy',
      'Y/m/d': 'yyyy/MM/dd',
    };

    return conversions[phpFormat] ?? 'dd/MM/yyyy';
  }

  /// Static helper for time ago (without config)
  static String timeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return '$minutes ${minutes == 1 ? 'min' : 'mins'} ago';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return '$hours ${hours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return '$days ${days == 1 ? 'day' : 'days'} ago';
    } else {
      return DateFormat('MMM d').format(dateTime);
    }
  }

  /// Static helper for time formatting (without config)
  static String formatTimeStatic(DateTime dateTime) {
    return DateFormat('h:mm a').format(dateTime);
  }
}

/// Extension on DateTime for easy formatting
extension DateTimeFormatterExtension on DateTime {
  String toFormattedDate(TimezoneConfig config) {
    return DateTimeFormatter(config).formatDate(this);
  }

  String toFormattedTime(TimezoneConfig config) {
    return DateTimeFormatter(config).formatTime(this);
  }

  String toFormattedDateTime(TimezoneConfig config) {
    return DateTimeFormatter(config).formatDateTime(this);
  }

  String toRelativeTime(TimezoneConfig config) {
    return DateTimeFormatter(config).formatRelative(this);
  }

  String toOrderDate(TimezoneConfig config) {
    return DateTimeFormatter(config).formatOrderDate(this);
  }
}
