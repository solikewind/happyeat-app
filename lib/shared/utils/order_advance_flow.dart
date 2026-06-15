import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_exception.dart';
import '../../data/models/models.dart';
import '../providers/app_providers.dart';
import '../widgets/brief_snack_bar.dart';
import '../widgets/order_complete_dialog.dart';
import 'order_status_display.dart';

/// 推进订单状态；目标为 completed 时先确认实收金额。
Future<bool> advanceOrderWithConfirm({
  required BuildContext context,
  required WidgetRef ref,
  required OrderModel order,
}) async {
  final next = OrderStatusDisplay.workbenchAdvanceTarget(order.status);
  if (next == null) return false;

  double? actualYuan;
  if (next == 'completed') {
    final label =
        OrderStatusDisplay.workbenchAdvanceLabel(order.status) ?? '完成';
    actualYuan = await confirmCompleteOrder(
      context,
      order: order,
      actionLabel: label,
    );
    if (actualYuan == null) return false;
  }

  try {
    await ref.read(orderRepositoryProvider).updateOrderStatus(
          order.id,
          next,
          actualYuan: actualYuan,
        );
    if (context.mounted) {
      showBriefSnackBar(
        context,
        OrderStatusDisplay.advanceSuccessMessage(next),
      );
    }
    return true;
  } on ApiException catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    }
    return false;
  }
}
