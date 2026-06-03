import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// 与后端订单状态（小写）及 Web 展示一致
class OrderStatusDisplay {
  OrderStatusDisplay._();

  static bool isActive(String status) {
    const active = {'created', 'paid', 'preparing'};
    return active.contains(status.trim().toLowerCase());
  }

  static String label(String status) {
    switch (status.trim().toLowerCase()) {
      case 'created':
        return '待支付';
      case 'paid':
        return '已支付';
      case 'preparing':
        return '制作中';
      case 'completed':
        return '已完成';
      case 'cancelled':
        return '已取消';
      default:
        return status;
    }
  }

  static Color color(String status) {
    switch (status.trim().toLowerCase()) {
      case 'created':
        return AppColors.warning;
      case 'paid':
        return AppColors.primary;
      case 'preparing':
        return Colors.deepPurple;
      case 'completed':
        return AppColors.success;
      case 'cancelled':
        return AppColors.textSecondary;
      default:
        return AppColors.textSecondary;
    }
  }

  /// 多笔进行中订单时取最需要关注的状态
  static String? strongestActiveStatus(Iterable<String> statuses) {
    final list = statuses.map((s) => s.trim().toLowerCase()).toList();
    if (list.contains('preparing')) return 'preparing';
    if (list.contains('paid')) return 'paid';
    if (list.contains('created')) return 'created';
    return list.isEmpty ? null : list.first;
  }
}
