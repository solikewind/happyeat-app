/// 订单、结账单等时间展示（含年份）。
abstract final class DateTimeDisplay {
  DateTimeDisplay._();

  /// 如 2026/6/16 18:42
  static String? formatDateTime(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final dt = DateTime.parse(raw).toLocal();
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return '${dt.year}/${dt.month}/${dt.day} $h:$m';
    } catch (_) {
      return raw;
    }
  }
}
