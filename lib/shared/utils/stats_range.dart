import 'package:intl/intl.dart';

enum StatsRangePreset { today, yesterday, last3d, last7d, last30d, custom }

class StatsRange {
  const StatsRange({
    required this.preset,
    required this.startDate,
    required this.endDate,
    required this.label,
  });

  final StatsRangePreset preset;
  final String startDate;
  final String endDate;
  final String label;

  static DateTime startOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static String formatDate(DateTime date) =>
      DateFormat('yyyy-MM-dd').format(startOfDay(date));

  static String formatChinese(String dateStr, {bool withYear = true}) {
    final parts = dateStr.split('-');
    if (parts.length != 3) return dateStr;
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final day = int.tryParse(parts[2]);
    if (year == null || month == null || day == null) return dateStr;
    return withYear ? '$year年$month月$day日' : '$month月$day日';
  }

  String get displayRange {
    if (startDate == endDate) return formatChinese(startDate);
    return '${formatChinese(startDate)} ~ ${formatChinese(endDate)}';
  }

  static StatsRange resolve(
    StatsRangePreset preset, {
    DateTime? customStart,
    DateTime? customEnd,
  }) {
    final today = startOfDay(DateTime.now());

    if (preset == StatsRangePreset.custom) {
      if (customStart == null || customEnd == null) {
        return resolve(StatsRangePreset.today);
      }
      var start = startOfDay(customStart);
      var end = startOfDay(customEnd);
      if (end.isBefore(start)) {
        final tmp = start;
        start = end;
        end = tmp;
      }
      return StatsRange(
        preset: preset,
        startDate: formatDate(start),
        endDate: formatDate(end),
        label: formatChinese(formatDate(start)) == formatChinese(formatDate(end))
            ? formatChinese(formatDate(start))
            : '${formatChinese(formatDate(start))} ~ ${formatChinese(formatDate(end))}',
      );
    }

    DateTime start = today;
    final end = today;
    var label = '今天';

    switch (preset) {
      case StatsRangePreset.today:
        break;
      case StatsRangePreset.yesterday:
        start = today.subtract(const Duration(days: 1));
        label = '昨天';
        return StatsRange(
          preset: preset,
          startDate: formatDate(start),
          endDate: formatDate(start),
          label: label,
        );
      case StatsRangePreset.last3d:
        start = today.subtract(const Duration(days: 2));
        label = '近3天';
        break;
      case StatsRangePreset.last7d:
        start = today.subtract(const Duration(days: 6));
        label = '近7天';
        break;
      case StatsRangePreset.last30d:
        start = today.subtract(const Duration(days: 29));
        label = '近30天';
        break;
      case StatsRangePreset.custom:
        break;
    }

    return StatsRange(
      preset: preset,
      startDate: formatDate(start),
      endDate: formatDate(end),
      label: label,
    );
  }
}
