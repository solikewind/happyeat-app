import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/models.dart';
import '../../../shared/providers/app_providers.dart';
import '../../../shared/utils/table_display.dart';

/// 点餐页：堂食/外带 + 选桌（同一行）
class OrderModeBar extends ConsumerWidget {
  const OrderModeBar({super.key, required this.onPickTable});

  final VoidCallback onPickTable;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderType = ref.watch(orderTypeProvider);
    final table = ref.watch(currentTableProvider);
    final categoryMap = ref.watch(tableCategoryMapProvider).valueOrNull ?? {};
    final isDineIn = orderType == 'dine_in';

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 11,
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'dine_in',
                  label: Text('堂食', style: TextStyle(fontSize: 13)),
                  icon: Icon(Icons.table_restaurant_outlined, size: 16),
                ),
                ButtonSegment(
                  value: 'takeaway',
                  label: Text('外带', style: TextStyle(fontSize: 13)),
                  icon: Icon(Icons.takeout_dining_outlined, size: 16),
                ),
              ],
              selected: {orderType},
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: WidgetStateProperty.all(
                  const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
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
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 13,
            child: isDineIn
                ? _TableChip(
                    table: table,
                    categoryMap: categoryMap,
                    onTap: onPickTable,
                  )
                : const _TakeawayHint(),
          ),
        ],
      ),
    );
  }
}

class _TakeawayHint extends StatelessWidget {
  const _TakeawayHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppStyles.surfaceMuted,
        borderRadius: BorderRadius.circular(AppStyles.radiusMd),
        border: Border.all(color: AppStyles.border),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.takeout_dining, size: 16, color: AppColors.textSecondary),
          SizedBox(width: 6),
          Text(
            '外带',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _TableChip extends StatelessWidget {
  const _TableChip({
    required this.table,
    required this.categoryMap,
    required this.onTap,
  });

  final TableItem? table;
  final Map<String, String> categoryMap;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasTable = table != null;
    final label = hasTable
        ? TableDisplay.tableLabel(table!, categoryMap)
        : '选餐桌';

    return Material(
      color: hasTable ? AppColors.primaryLight : const Color(0xFFFFF7ED),
      borderRadius: BorderRadius.circular(AppStyles.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppStyles.radiusMd),
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 10),
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
              Icon(
                Icons.table_restaurant_rounded,
                size: 18,
                color: hasTable ? AppColors.primary : const Color(0xFFC2410C),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: hasTable
                        ? AppStyles.textPrimary
                        : const Color(0xFFC2410C),
                  ),
                ),
              ),
              Icon(
                Icons.expand_more_rounded,
                size: 20,
                color: hasTable ? AppColors.primary : const Color(0xFFC2410C),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
