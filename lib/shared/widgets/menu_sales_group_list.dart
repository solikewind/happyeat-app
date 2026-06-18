import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/money.dart';
import '../utils/sales_stats.dart';

/// 右侧数量/金额列固定宽度，保证有规格展开行与无规格行对齐。
const _kMetricsWidth = 72.0;
const _kExpandSlotWidth = 24.0;

class MenuSalesGroupList extends StatefulWidget {
  const MenuSalesGroupList({super.key, required this.rows, this.dense = false});

  final List<MenuSalesRow> rows;
  final bool dense;

  @override
  State<MenuSalesGroupList> createState() => _MenuSalesGroupListState();
}

class _MenuSalesGroupListState extends State<MenuSalesGroupList> {
  final _expandedKeys = <String>{};

  void _toggle(String key) {
    setState(() {
      if (_expandedKeys.contains(key)) {
        _expandedKeys.remove(key);
      } else {
        _expandedKeys.add(key);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final groups = groupMenuSalesRows(widget.rows);
    return Column(
      children: [
        for (var index = 0; index < groups.length; index++)
          _MenuSalesGroupTile(
            rank: index + 1,
            group: groups[index],
            dense: widget.dense,
            expanded: _expandedKeys.contains(groups[index].key),
            onToggle: () => _toggle(groups[index].key),
          ),
      ],
    );
  }
}

class _MenuSalesGroupTile extends StatelessWidget {
  const _MenuSalesGroupTile({
    required this.rank,
    required this.group,
    required this.dense,
    required this.expanded,
    required this.onToggle,
  });

  final int rank;
  final MenuSalesGroup group;
  final bool dense;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final avatarRadius = dense ? 16.0 : 18.0;
    final titleSize = dense ? 14.0 : 15.0;

    return Card(
      margin: EdgeInsets.only(bottom: dense ? 8 : 10),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            onTap: group.canExpand ? onToggle : null,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                12,
                dense ? 10 : 12,
                12,
                dense ? 10 : 12,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: avatarRadius,
                    backgroundColor: AppColors.primaryLight,
                    child: Text(
                      '$rank',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: dense ? 12 : 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      group.menuName,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: titleSize,
                      ),
                    ),
                  ),
                  _MenuSalesMetrics(
                    quantity: group.quantity,
                    amount: group.amount,
                    dense: dense,
                  ),
                  _ExpandSlot(showIcon: group.canExpand, expanded: expanded),
                ],
              ),
            ),
          ),
          if (group.canExpand && expanded)
            Column(
              children: [
                for (var i = 0; i < group.variants.length; i++) ...[
                  if (i == 0)
                    const Divider(height: 1)
                  else
                    const Divider(height: 1, indent: 56, endIndent: 12),
                  _MenuSalesVariantRow(row: group.variants[i], dense: dense),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

class _MenuSalesVariantRow extends StatelessWidget {
  const _MenuSalesVariantRow({required this.row, required this.dense});

  final MenuSalesRow row;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final spec = row.displaySpec;
    return Padding(
      padding: EdgeInsets.fromLTRB(56, dense ? 8 : 10, 12, dense ? 8 : 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              spec.isEmpty ? '默认规格' : spec,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.35,
              ),
            ),
          ),
          _MenuSalesMetrics(
            quantity: row.quantity,
            amount: row.amount,
            dense: dense,
          ),
          const _ExpandSlot(showIcon: false, expanded: false),
        ],
      ),
    );
  }
}

class _MenuSalesMetrics extends StatelessWidget {
  const _MenuSalesMetrics({
    required this.quantity,
    required this.amount,
    required this.dense,
  });

  final int quantity;
  final double amount;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _kMetricsWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '×$quantity',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: dense ? 15 : 16,
            ),
          ),
          Text(
            Money.formatYuan(amount),
            style: TextStyle(
              color: AppColors.error,
              fontSize: dense ? 11 : 12,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.right,
          ),
        ],
      ),
    );
  }
}

class _ExpandSlot extends StatelessWidget {
  const _ExpandSlot({required this.showIcon, required this.expanded});

  final bool showIcon;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _kExpandSlotWidth,
      child: showIcon
          ? Icon(
              expanded
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
              color: AppColors.textSecondary,
              size: 24,
            )
          : null,
    );
  }
}
