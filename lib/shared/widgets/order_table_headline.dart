import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/models.dart';

/// 订单主视觉：桌号/外带（横向自适应，长桌名可换行省略）
class OrderTableHeadline extends StatelessWidget {
  const OrderTableHeadline({
    super.key,
    required this.order,
    this.compact = false,
  });

  final OrderModel order;
  final bool compact;

  bool get _isDineIn => order.orderType == 'dine_in';

  @override
  Widget build(BuildContext context) {
    final color = _isDineIn ? AppColors.primary : AppColors.warning;
    final title = order.locationLabel;
    final iconSize = compact ? 20.0 : 24.0;
    final fontSize = compact ? 20.0 : 26.0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(
            _isDineIn ? Icons.table_restaurant_outlined : Icons.takeout_dining,
            color: color,
            size: iconSize,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            maxLines: compact ? 2 : 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: fontSize,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
        ),
      ],
    );
  }
}
