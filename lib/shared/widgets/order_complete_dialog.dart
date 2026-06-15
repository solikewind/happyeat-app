import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/money.dart';
import '../../data/models/models.dart';

/// 完成/出单前确认实收金额；取消返回 null。
Future<double?> confirmCompleteOrder(
  BuildContext context, {
  required OrderModel order,
  required String actionLabel,
}) async {
  final preset = (order.actualAmount != null && order.actualAmount! > 0)
      ? order.actualAmount!
      : order.totalAmount;
  final rounded = (preset * 100).round() / 100;
  final amountCtrl = TextEditingController(text: rounded.toStringAsFixed(2));

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(actionLabel),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '应收 ${Money.formatYuan(order.totalAmount)}',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: amountCtrl,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: '实收金额'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text('确认$actionLabel'),
        ),
      ],
    ),
  );

  if (confirmed != true) {
    amountCtrl.dispose();
    return null;
  }

  final actual = double.tryParse(amountCtrl.text.trim());
  amountCtrl.dispose();
  if (actual == null || actual < 0) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入有效实收金额')),
      );
    }
    return null;
  }

  return (actual * 100).round() / 100;
}
