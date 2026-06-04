import 'package:flutter/material.dart';

import '../../core/theme/app_styles.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/models.dart';
import '../utils/table_display.dart';

/// 桌台紧凑块：仅桌号 + 状态（选桌、厅面看板共用）
class TableCompactTile extends StatelessWidget {
  const TableCompactTile({
    super.key,
    required this.table,
    required this.onTap,
    this.selected = false,
  });

  final TableItem table;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final statusColor = TableDisplay.statusColor(table.status);
    final statusLabel = TableDisplay.statusLabel(table.status);

    return Material(
      color: selected ? AppColors.primaryLight : Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? AppColors.primary : AppStyles.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                table.code,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: selected ? AppColors.primary : AppStyles.textPrimary,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                statusLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 厅面/选桌网格默认布局
const tableCompactGridDelegate = SliverGridDelegateWithFixedCrossAxisCount(
  crossAxisCount: 5,
  mainAxisSpacing: 6,
  crossAxisSpacing: 6,
  childAspectRatio: 1.45,
);
