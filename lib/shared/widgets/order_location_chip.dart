import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/models.dart';

/// 订单桌位/外带标识，对齐 Web 工作台 location chip（紧凑、右上角展示）
class OrderLocationChip extends StatelessWidget {
  const OrderLocationChip({super.key, required this.order});

  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    final isDineIn = order.orderType == 'dine_in';
    final color = isDineIn ? AppColors.primary : AppColors.warning;
    final label = isDineIn ? order.locationLabel : '外带';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDineIn ? 0.1 : 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 13,
          fontWeight: FontWeight.w700,
          height: 1.2,
        ),
      ),
    );
  }
}
