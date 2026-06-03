import 'package:flutter/material.dart';

import '../../shared/utils/order_status_display.dart';

class OrderStatusChip extends StatelessWidget {
  const OrderStatusChip({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final meta = (
      label: OrderStatusDisplay.label(status),
      color: OrderStatusDisplay.color(status),
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: meta.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        meta.label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: meta.color,
        ),
      ),
    );
  }
}
