import 'datetime_display.dart';

abstract final class SettlementDisplay {
  SettlementDisplay._();

  static String statusLabel(String status) {
    switch (status.trim().toUpperCase()) {
      case 'SETTLED':
        return '已结账';
      case 'UNSETTLED':
        return '未结账';
      default:
        return status;
    }
  }

  static bool isUnsettled(String status) =>
      status.trim().toUpperCase() == 'UNSETTLED';

  static String? formatDateTime(String? raw) => DateTimeDisplay.formatDateTime(raw);
}
