import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../utils/order_status_display.dart';

/// 工作台主操作：开始制作 / 出单完成（调用方负责调 API 与刷新）
class OrderAdvanceButton extends StatelessWidget {
  const OrderAdvanceButton({
    super.key,
    required this.status,
    required this.onPressed,
    this.loading = false,
    this.compact = false,
  });

  final String status;
  final VoidCallback? onPressed;
  final bool loading;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final label = OrderStatusDisplay.workbenchAdvanceLabel(status);
    if (label == null) return const SizedBox.shrink();

    final child = loading
        ? SizedBox(
            width: compact ? 18 : 22,
            height: compact ? 18 : 22,
            child: const CircularProgressIndicator(strokeWidth: 2),
          )
        : Text(label);

    if (compact) {
      return FilledButton(
        onPressed: loading ? null : onPressed,
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 32),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          backgroundColor: AppColors.primary,
        ),
        child: child,
      );
    }

    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: loading ? null : onPressed,
        icon: loading
            ? const SizedBox.shrink()
            : Icon(
                OrderStatusDisplay.workbenchAdvanceLabel(status) == '开始制作'
                    ? Icons.play_circle_outline
                    : Icons.check_circle_outline,
              ),
        label: child,
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          backgroundColor: AppColors.primary,
        ),
      ),
    );
  }
}
