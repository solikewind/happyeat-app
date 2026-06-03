import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/models.dart';
import '../../../shared/providers/app_providers.dart';

/// 点餐页：堂食/外带 + 选桌（纵向布局，适配手机）
class OrderModeBar extends ConsumerWidget {
  const OrderModeBar({
    super.key,
    required this.onPickTable,
  });

  final VoidCallback onPickTable;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderType = ref.watch(orderTypeProvider);
    final table = ref.watch(currentTableProvider);
    final isDineIn = orderType == 'dine_in';

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                value: 'dine_in',
                label: Text('堂食'),
                icon: Icon(Icons.table_restaurant_outlined, size: 18),
              ),
              ButtonSegment(
                value: 'takeaway',
                label: Text('外带'),
                icon: Icon(Icons.takeout_dining_outlined, size: 18),
              ),
            ],
            selected: {orderType},
            style: ButtonStyle(
              visualDensity: VisualDensity.compact,
              padding: WidgetStateProperty.all(
                const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
            onSelectionChanged: (selected) {
              if (selected.isEmpty) return;
              final next = selected.first;
              ref.read(orderTypeProvider.notifier).state = next;
              if (next == 'takeaway') {
                ref.read(currentTableProvider.notifier).state = null;
              } else if (ref.read(currentTableProvider) == null) {
                onPickTable();
              }
            },
          ),
          const SizedBox(height: 10),
          if (isDineIn)
            _TableChip(table: table, onTap: onPickTable)
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppStyles.surfaceMuted,
                borderRadius: BorderRadius.circular(AppStyles.radiusMd),
                border: Border.all(color: AppStyles.border),
              ),
              child: const Row(
                children: [
                  Icon(Icons.takeout_dining, size: 18, color: AppColors.textSecondary),
                  SizedBox(width: 8),
                  Text(
                    '打包外带，无需选择餐桌',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _TableChip extends StatelessWidget {
  const _TableChip({required this.table, required this.onTap});

  final TableItem? table;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasTable = table != null;
    return Material(
      color: hasTable ? AppColors.primaryLight : const Color(0xFFFFF7ED),
      borderRadius: BorderRadius.circular(AppStyles.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppStyles.radiusMd),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppStyles.radiusMd),
            border: Border.all(
              color: hasTable
                  ? AppColors.primary.withValues(alpha: 0.35)
                  : const Color(0xFFFDBA74),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: hasTable
                      ? AppColors.primary.withValues(alpha: 0.15)
                      : const Color(0xFFFFEDD5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.table_restaurant_rounded,
                  size: 20,
                  color: hasTable ? AppColors.primary : const Color(0xFFC2410C),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasTable ? '当前餐桌' : '请选择餐桌',
                      style: TextStyle(
                        fontSize: 11,
                        color: hasTable
                            ? AppColors.primary
                            : const Color(0xFFC2410C),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hasTable
                          ? '${table!.code} · ${table!.capacity} 人'
                          : '点击打开桌台列表',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: hasTable
                            ? AppStyles.textPrimary
                            : const Color(0xFFC2410C),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.keyboard_arrow_right_rounded,
                color: hasTable ? AppColors.primary : const Color(0xFFC2410C),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
