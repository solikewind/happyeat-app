/// 金额工具：后端 price / price_delta / total_amount 均为「分」，界面按「元」展示。
class Money {
  Money._();

  /// 接口金额（分）→ 元
  static double apiCentsToYuan(num cents) => cents / 100;

  /// 分 → 元字符串（如 2800 → "28.00"）
  static String centsToYuan(int cents) {
    return (cents / 100).toStringAsFixed(2);
  }

  /// 元 → 分（下单用）
  static int yuanToCents(double yuan) {
    return (yuan * 100).round();
  }

  /// 展示：¥28.00
  static String formatYuan(double yuan) => '¥${yuan.toStringAsFixed(2)}';

  /// 规格加价展示：+¥2.00
  static String formatDeltaYuan(double yuan) {
    if (yuan <= 0) return '';
    return ' +${formatYuan(yuan)}';
  }
}
