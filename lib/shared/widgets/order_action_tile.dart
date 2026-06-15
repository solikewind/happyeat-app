import 'package:flutter/material.dart';

import '../../core/theme/app_styles.dart';
import '../../core/theme/app_theme.dart';
import '../utils/order_status_display.dart';

/// 订单紧凑操作行（列表卡片、详情底栏共用）：完成 / 取消 / 打印 / 记账 / 加菜
class OrderCompactActionRow extends StatelessWidget {
  const OrderCompactActionRow({
    super.key,
    required this.status,
    this.onAdvance,
    this.advancing = false,
    this.onAddItems,
    this.onPrint,
    this.printing = false,
    this.onRemove,
    this.removing = false,
    this.removeLabel = '取消',
    this.isDelete = false,
    this.onSettlement,
    this.settlementLabel = '记账',
    this.settlementLoading = false,
  });

  final String status;
  final VoidCallback? onAdvance;
  final bool advancing;
  final VoidCallback? onAddItems;
  final VoidCallback? onPrint;
  final bool printing;
  final VoidCallback? onRemove;
  final bool removing;
  final String removeLabel;
  final bool isDelete;
  final VoidCallback? onSettlement;
  final String settlementLabel;
  final bool settlementLoading;

  @override
  Widget build(BuildContext context) {
    final advanceLabel = OrderStatusDisplay.workbenchAdvanceLabel(status);
    final tiles = <Widget>[];

    void pushTile(Widget tile, {int flex = 1}) {
      if (tiles.isNotEmpty) tiles.add(const SizedBox(width: 6));
      tiles.add(Expanded(flex: flex, child: tile));
    }

    if (onAdvance != null && advanceLabel != null) {
      final isPrepare = advanceLabel == '开始制作';
      pushTile(
        OrderActionTile(
          icon: isPrepare
              ? Icons.play_circle_outline_rounded
              : Icons.check_circle_outline_rounded,
          label: advanceLabel,
          color: Colors.white,
          backgroundColor: AppColors.primary,
          compact: true,
          loading: advancing,
          onTap: advancing ? null : onAdvance,
        ),
        flex: 2,
      );
    }

    if (onRemove != null) {
      pushTile(
        OrderActionTile(
          icon: isDelete ? Icons.delete_outline_rounded : Icons.close_rounded,
          label: removeLabel,
          color: AppColors.error,
          backgroundColor: AppColors.error.withValues(alpha: 0.08),
          compact: true,
          loading: removing,
          onTap: removing ? null : onRemove,
        ),
      );
    }

    if (onPrint != null) {
      pushTile(
        OrderActionTile(
          icon: Icons.print_outlined,
          label: '打印',
          compact: true,
          loading: printing,
          onTap: printing ? null : onPrint,
        ),
      );
    }

    if (onSettlement != null) {
      pushTile(
        OrderActionTile(
          icon: Icons.receipt_long_outlined,
          label: settlementLabel,
          color: AppColors.warning,
          backgroundColor: AppColors.warning.withValues(alpha: 0.12),
          compact: true,
          loading: settlementLoading,
          onTap: settlementLoading ? null : onSettlement,
        ),
      );
    }

    if (onAddItems != null) {
      pushTile(
        OrderActionTile(
          icon: Icons.add_circle_outline_rounded,
          label: '加菜',
          color: AppColors.primary,
          backgroundColor: AppColors.primaryLight,
          compact: true,
          onTap: onAddItems,
        ),
      );
    }

    if (tiles.isEmpty) return const SizedBox.shrink();
    return Row(children: tiles);
  }
}

/// 订单列表卡片操作栏：主按钮「完成」+ 次要操作图标（Tooltip）
class OrderListActionBar extends StatelessWidget {
  const OrderListActionBar({
    super.key,
    required this.status,
    this.onAdvance,
    this.advancing = false,
    this.onAddItems,
    this.onPrint,
    this.printing = false,
    this.onRemove,
    this.removing = false,
    this.removeLabel = '取消',
    this.isDelete = false,
    this.hidePrintAndRemove = false,
  });

  final String status;
  final VoidCallback? onAdvance;
  final bool advancing;
  final VoidCallback? onAddItems;
  final VoidCallback? onPrint;
  final bool printing;
  final VoidCallback? onRemove;
  final bool removing;
  final String removeLabel;
  final bool isDelete;
  /// 进行中订单：打印/取消改由左滑露出，底栏不展示
  final bool hidePrintAndRemove;

  @override
  Widget build(BuildContext context) {
    final advanceLabel = OrderStatusDisplay.workbenchAdvanceLabel(status);
    final hasAdvance = onAdvance != null && advanceLabel != null;
    final icons = <Widget>[];

    if (onPrint != null && !hidePrintAndRemove) {
      icons.add(
        _OrderListIconAction(
          icon: Icons.print_outlined,
          tooltip: '打印',
          color: AppStyles.textPrimary,
          loading: printing,
          onTap: printing ? null : onPrint,
        ),
      );
    }
    if (onRemove != null && !hidePrintAndRemove) {
      icons.add(
        _OrderListIconAction(
          icon: isDelete ? Icons.delete_outline_rounded : Icons.close_rounded,
          tooltip: removeLabel,
          color: AppColors.error,
          backgroundColor: AppColors.error.withValues(alpha: 0.08),
          loading: removing,
          onTap: removing ? null : onRemove,
        ),
      );
    }
    if (onAddItems != null) {
      icons.add(
        _OrderListIconAction(
          icon: Icons.add_circle_outline_rounded,
          tooltip: '加菜',
          color: AppColors.primary,
          backgroundColor: AppColors.primaryLight,
          onTap: onAddItems,
        ),
      );
    }

    if (!hasAdvance && icons.isEmpty) return const SizedBox.shrink();

    final spacedIcons = <Widget>[];
    for (var i = 0; i < icons.length; i++) {
      if (i > 0) spacedIcons.add(const SizedBox(width: 6));
      spacedIcons.add(icons[i]);
    }

    return Row(
      children: [
        if (hasAdvance) ...[
          Expanded(
            child: SizedBox(
              height: 40,
              child: FilledButton.icon(
                onPressed: advancing ? null : onAdvance,
                icon: advancing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(
                        advanceLabel == '开始制作'
                            ? Icons.play_circle_outline_rounded
                            : Icons.check_circle_outline_rounded,
                        size: 20,
                      ),
                label: Text(advanceLabel),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  textStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          if (spacedIcons.isNotEmpty) const SizedBox(width: 8),
        ],
        if (!hasAdvance && spacedIcons.isNotEmpty) const Spacer(),
        ...spacedIcons,
      ],
    );
  }
}

class _OrderListIconAction extends StatelessWidget {
  const _OrderListIconAction({
    required this.icon,
    required this.tooltip,
    required this.color,
    this.backgroundColor,
    this.onTap,
    this.loading = false,
  });

  final IconData icon;
  final String tooltip;
  final Color color;
  final Color? backgroundColor;
  final VoidCallback? onTap;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      preferBelow: false,
      child: Material(
        color: backgroundColor ?? AppStyles.surfaceMuted,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            width: 40,
            height: 40,
            child: Center(
              child: loading
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: color,
                      ),
                    )
                  : Icon(icon, size: 22, color: color),
            ),
          ),
        ),
      ),
    );
  }
}

/// 订单操作图标按钮（详情底栏共用）
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
