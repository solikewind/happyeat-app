import 'package:flutter/material.dart';

import '../../core/theme/app_styles.dart';
import '../../core/theme/app_theme.dart';

/// 订单操作图标按钮（详情底栏、列表卡片共用）
class OrderActionTile extends StatelessWidget {
  const OrderActionTile({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
    this.backgroundColor,
    this.loading = false,
    this.compact = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color? color;
  final Color? backgroundColor;
  final bool loading;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final fg = color ?? AppStyles.textPrimary;
    final iconSize = compact ? 20.0 : 22.0;

    return Material(
      color: backgroundColor ?? AppStyles.surfaceMuted,
      borderRadius: BorderRadius.circular(compact ? 10 : 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(compact ? 10 : 12),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: compact ? 8 : 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (loading)
                SizedBox(
                  width: iconSize,
                  height: iconSize,
                  child: CircularProgressIndicator(strokeWidth: 2, color: fg),
                )
              else
                Icon(icon, size: iconSize, color: fg),
              SizedBox(height: compact ? 2 : 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: compact ? 11 : 12,
                  fontWeight: FontWeight.w600,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 列表卡片内次要操作行（加菜 / 打印 / 取消）
class OrderCardSecondaryActions extends StatelessWidget {
  const OrderCardSecondaryActions({
    super.key,
    this.onAddItems,
    this.onPrint,
    this.printing = false,
    this.onRemove,
    this.removing = false,
    this.removeLabel = '取消',
    this.isDelete = false,
  });

  final VoidCallback? onAddItems;
  final VoidCallback? onPrint;
  final bool printing;
  final VoidCallback? onRemove;
  final bool removing;
  final String removeLabel;
  final bool isDelete;

  @override
  Widget build(BuildContext context) {
    final tiles = <Widget>[];
    if (onAddItems != null) {
      tiles.add(
        Expanded(
          child: OrderActionTile(
            icon: Icons.add_circle_outline_rounded,
            label: '加菜',
            color: AppColors.primary,
            backgroundColor: AppColors.primaryLight,
            compact: true,
            onTap: onAddItems!,
          ),
        ),
      );
    }
    if (onPrint != null) {
      if (tiles.isNotEmpty) tiles.add(const SizedBox(width: 8));
      tiles.add(
        Expanded(
          child: OrderActionTile(
            icon: Icons.print_outlined,
            label: '打印',
            compact: true,
            loading: printing,
            onTap: printing ? null : onPrint!,
          ),
        ),
      );
    }
    if (onRemove != null) {
      if (tiles.isNotEmpty) tiles.add(const SizedBox(width: 8));
      tiles.add(
        Expanded(
          child: OrderActionTile(
            icon: isDelete ? Icons.delete_outline_rounded : Icons.close_rounded,
            label: removeLabel,
            color: AppColors.error,
            backgroundColor: AppColors.error.withValues(alpha: 0.08),
            compact: true,
            loading: removing,
            onTap: removing ? null : onRemove!,
          ),
        ),
      );
    }
    if (tiles.isEmpty) return const SizedBox.shrink();
    return Row(children: tiles);
  }
}
