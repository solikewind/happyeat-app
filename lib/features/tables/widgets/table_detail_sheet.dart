import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/money.dart';
import '../../../data/models/models.dart';
import '../../../shared/utils/order_status_display.dart';
import '../../../shared/utils/table_display.dart';
import '../../../shared/widgets/order_status_chip.dart';

void showTableDetailSheet(
  BuildContext context, {
  required TableItem table,
  String? categoryName,
  required List<OrderModel> activeOrders,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (ctx) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.5,
      minChildSize: 0.35,
      maxChildSize: 0.85,
      builder: (_, controller) => _TableDetailBody(
        scrollController: controller,
        table: table,
        categoryName: categoryName,
        activeOrders: activeOrders,
      ),
    ),
  );
}

class _TableDetailBody extends StatelessWidget {
  const _TableDetailBody({
    required this.scrollController,
    required this.table,
    this.categoryName,
    required this.activeOrders,
  });

  final ScrollController scrollController;
  final TableItem table;
  final String? categoryName;
  final List<OrderModel> activeOrders;

  @override
  Widget build(BuildContext context) {
    final statusColor = TableDisplay.statusColor(table.status);

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      children: [
        Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                TableDisplay.statusIcon(table.status),
                color: statusColor,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    table.code,
                    style: AppStyles.pageTitle.copyWith(fontSize: 22),
                  ),
                  Text(
                    [
                      if (categoryName != null && categoryName!.isNotEmpty)
                        categoryName!,
                      '${table.capacity} 人',
                      TableDisplay.statusLabel(table.status),
                    ].join(' · '),
                    style: AppStyles.pageSubtitle,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          activeOrders.isEmpty ? '当前无进行中订单' : '进行中订单（${activeOrders.length}）',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 10),
        if (activeOrders.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppStyles.surfaceMuted,
              borderRadius: BorderRadius.circular(AppStyles.radiusMd),
              border: Border.all(color: AppStyles.border),
            ),
            child: const Text(
              '桌台处于空闲或仅有已完成订单。\n如需开台点单，请到「点餐」页选择本桌。',
              style: TextStyle(
                color: AppColors.textSecondary,
                height: 1.45,
              ),
            ),
          )
        else
          ...activeOrders.map(
            (order) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                onTap: () {
                  Navigator.pop(context);
                  context.push('/orders/${order.id}');
                },
                title: Text(
                  order.orderNo.isNotEmpty ? order.orderNo : '#${order.id}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  [
                    Money.formatYuan(order.totalAmount),
                    if (order.createdAtLabel != null) order.createdAtLabel!,
                  ].join(' · '),
                ),
                trailing: OrderStatusChip(status: order.status),
              ),
            ),
          ),
        const SizedBox(height: 12),
        Text(
          '本页仅查看厅面状态；选桌开单请在「点餐」页操作。',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary.withValues(alpha: 0.9),
          ),
        ),
      ],
    );
  }
}
