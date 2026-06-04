/// 金额工具：接口 price / price_delta / total_amount 均按「元」传递。
class Money {
  Money._();

  /// 接口金额 → 元
  static double apiAmountToYuan(num amount) => amount.toDouble();

  /// 元 → 接口金额（下单用）
  static double yuanToApiAmount(double yuan) => yuan;

  /// 展示：¥28.00
  static String formatYuan(double yuan) => '¥${yuan.toStringAsFixed(2)}';

  /// 规格加价展示：+¥2.00
  static String formatDeltaYuan(double yuan) {
    if (yuan <= 0) return '';
    return ' +${formatYuan(yuan)}';
  }
}
