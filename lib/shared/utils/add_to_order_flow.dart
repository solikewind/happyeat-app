import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_exception.dart';
import '../../data/models/models.dart';
import '../providers/add_to_order_provider.dart';
import '../providers/app_providers.dart';
import 'order_status_display.dart';

/// 进入「为指定订单加菜」流程：拉菜单映射、同步桌台/类型、清空购物车并跳转点餐页
Future<void> startAddToOrderFlow(
  BuildContext context,
  WidgetRef ref, {
  required OrderModel order,
}) async {
  if (!OrderStatusDisplay.canAddItems(order.status)) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('该订单已结束，无法加菜')));
    return;
  }

  try {
    final menus = await ref.read(menuRepositoryProvider).listMenus();
    final menuNameToId = {for (final m in menus) m.name: m.id};

    ref.read(addToOrderProvider.notifier).start(order, menuNameToId);
    ref.read(cartProvider.notifier).clear();
    ref.read(orderTypeProvider.notifier).state = order.orderType;

    if (order.orderType == 'dine_in' && order.tableId != null) {
      final tables = await ref.read(tableRepositoryProvider).listTables();
      TableItem? table;
      for (final t in tables) {
        if (t.id == order.tableId) {
          table = t;
          break;
        }
      }
      if (table != null) {
        ref.read(currentTableProvider.notifier).state = table;
      }
    } else if (order.orderType == 'takeaway') {
      ref.read(currentTableProvider.notifier).state = null;
    }

    if (!context.mounted) return;
    final loc = order.locationLabel;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('正在为 $loc 加菜，选菜后点「确认加菜」'),
        duration: const Duration(seconds: 2),
      ),
    );
    context.go('/');
  } on ApiException catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }
}
