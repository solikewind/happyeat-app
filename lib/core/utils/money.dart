/// 金额工具：与 Web 点餐台一致，接口 amount 字段为 int64（库内按「元」整数存，如 45 表示 ¥45）。
class Money {
  Money._();

  /// 接口金额 → 元
  static double apiAmountToYuan(num amount) => amount.toDouble();

  /// 元 → 接口 int64。必须用整数，避免 Dio 序列化成 `28.0` 导致 go-zero ParseInt 失败（HTTP 500）。
  static int yuanToApiInt(double yuan) {
    // 与 Web `Math.round(x * 100) / 100` 后再提交整数一致
    return ((yuan * 100).round() / 100).round();
  }

  /// 展示：¥28.00
  static String formatYuan(double yuan) => '¥${yuan.toStringAsFixed(2)}';

  /// 规格加价展示：+¥2.00
  static String formatDeltaYuan(double yuan) {
    if (yuan <= 0) return '';
    return ' +${formatYuan(yuan)}';
  }
}
