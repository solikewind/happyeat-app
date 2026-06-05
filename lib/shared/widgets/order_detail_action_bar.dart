import 'package:flutter/material.dart';

import '../../core/theme/app_styles.dart';
import '../../core/theme/app_theme.dart';
import '../utils/order_status_display.dart';
import 'order_action_tile.dart';
import 'order_advance_button.dart';

/// 订单详情底部操作栏
class OrderDetailActionBar extends StatelessWidget {
  const OrderDetailActionBar({
    super.key,
    this.onAddItems,
    this.onPrint,
    this.printing = false,
    required this.status,
    this.onAdvance,
    this.advancing = false,
    this.onRemove,
    this.removing = false,
    this.removeLabel = '取消',
    this.isDelete = false,
  });

  final VoidCallback? onAddItems;
  final VoidCallback? onPrint;
  final bool printing;
  final String status;
  final VoidCallback? onAdvance;
  final bool advancing;
  final VoidCallback? onRemove;
  final bool removing;
  final String removeLabel;
  final bool isDelete;

  bool get _showAdvance =>
      onAdvance != null &&
      OrderStatusDisplay.workbenchAdvanceLabel(status) != null;

  @override
  Widget build(BuildContext context) {
    final secondaries = <Widget>[];
    if (onAddItems != null) {
      secondaries.add(
        Expanded(
          child: OrderActionTile(
            icon: Icons.add_circle_outline_rounded,
            label: '加菜',
            color: AppColors.primary,
            backgroundColor: AppColors.primaryLight,
            onTap: onAddItems!,
          ),
        ),
      );
    }
    if (onPrint != null) {
      if (secondaries.isNotEmpty) secondaries.add(const SizedBox(width: 8));
      secondaries.add(
        Expanded(
          child: OrderActionTile(
            icon: Icons.print_outlined,
            label: '打印',
            loading: printing,
            onTap: printing ? null : onPrint!,
          ),
        ),
      );
    }
    if (onRemove != null) {
      if (secondaries.isNotEmpty) secondaries.add(const SizedBox(width: 8));
      secondaries.add(
        Expanded(
          child: OrderActionTile(
            icon: isDelete ? Icons.delete_outline_rounded : Icons.close_rounded,
            label: removeLabel,
            color: AppColors.error,
            backgroundColor: AppColors.error.withValues(alpha: 0.08),
            loading: removing,
            onTap: removing ? null : onRemove!,
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: AppStyles.border)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF101828).withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_showAdvance) ...[
                OrderAdvanceButton(
                  status: status,
                  loading: advancing,
                  onPressed: onAdvance,
                ),
                if (secondaries.isNotEmpty) const SizedBox(height: 10),
              ],
              if (secondaries.isNotEmpty) Row(children: secondaries),
            ],
          ),
        ),
      ),
    );
  }
}
