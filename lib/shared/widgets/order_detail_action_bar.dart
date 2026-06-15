import 'package:flutter/material.dart';

import '../../core/theme/app_styles.dart';
import 'order_action_tile.dart';

/// 订单详情底部操作栏：单行紧凑排列（完成 / 取消 / 打印 / 记账 / 加菜）
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
    this.onSettlement,
    this.settlementLabel = '记账',
    this.settlementLoading = false,
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
  final VoidCallback? onSettlement;
  final String settlementLabel;
  final bool settlementLoading;

  @override
  Widget build(BuildContext context) {
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
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: OrderCompactActionRow(
            status: status,
            onAdvance: onAdvance,
            advancing: advancing,
            onAddItems: onAddItems,
            onPrint: onPrint,
            printing: printing,
            onRemove: onRemove,
            removing: removing,
            removeLabel: removeLabel,
            isDelete: isDelete,
            onSettlement: onSettlement,
            settlementLabel: settlementLabel,
            settlementLoading: settlementLoading,
          ),
        ),
      ),
    );
  }
}
