import 'package:flutter/material.dart';

import '../../../core/theme/app_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/models.dart';
import '../../../shared/utils/order_status_display.dart';
import '../../../shared/utils/table_display.dart';

/// 厅面看板上的桌台卡片（只展示状态，非选桌控件）
class TableFloorTile extends StatelessWidget {
  const TableFloorTile({
    super.key,
    required this.table,
    this.activeOrderStatus,
    this.activeOrderCount = 0,
    required this.onTap,
  });

  final TableItem table;
  final String? activeOrderStatus;
  final int activeOrderCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final statusColor = TableDisplay.statusColor(table.status);
    final hasOrders = activeOrderCount > 0 && activeOrderStatus != null;

    return Material(
      color: hasOrders
          ? OrderStatusDisplay.color(activeOrderStatus!).withValues(alpha: 0.06)
          : TableDisplay.statusSurface(table.status),
      borderRadius: BorderRadius.circular(AppStyles.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppStyles.radiusMd),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppStyles.radiusMd),
            border: Border.all(
              color: hasOrders
                  ? OrderStatusDisplay.color(activeOrderStatus!)
                      .withValues(alpha: 0.45)
                  : statusColor.withValues(alpha: 0.35),
              width: hasOrders ? 2 : 1,
            ),
          ),
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                table.code,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: hasOrders
                      ? AppStyles.textPrimary
                      : statusColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${table.capacity} 人',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    TableDisplay.statusIcon(table.status),
                    size: 14,
                    color: statusColor,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      TableDisplay.statusLabel(table.status),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (hasOrders) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: OrderStatusDisplay.color(activeOrderStatus!)
                        .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${OrderStatusDisplay.label(activeOrderStatus!)} · $activeOrderCount单',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: OrderStatusDisplay.color(activeOrderStatus!),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
