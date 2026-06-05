import 'package:flutter/material.dart';

import '../../core/theme/app_styles.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/money.dart';

/// 点餐页底部购物车条
class CartBottomBar extends StatelessWidget {
  const CartBottomBar({
    super.key,
    required this.itemCount,
    required this.totalYuan,
    required this.onTap,
    required this.onCheckout,
    this.checkoutLabel = '去结算',
    this.cartTitle,
  });

  final int itemCount;
  final double totalYuan;
  final VoidCallback? onTap;
  final VoidCallback? onCheckout;
  final String checkoutLabel;
  final String? cartTitle;

  @override
  Widget build(BuildContext context) {
    final hasItems = itemCount > 0;
    return Material(
      elevation: 16,
      shadowColor: Colors.black.withValues(alpha: 0.18),
      borderRadius: const BorderRadius.vertical(top: Radius.circular(AppStyles.radiusXl)),
      color: AppStyles.cartBarBg,
      child: SafeArea(
        top: false,
        child: InkWell(
          onTap: hasItems ? onTap : null,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppStyles.radiusXl)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: hasItems
                        ? const LinearGradient(
                            colors: [Color(0xFF4096FF), AppColors.primary],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: hasItems ? null : Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: hasItems
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.35),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        Icons.shopping_bag_outlined,
                        color: hasItems ? Colors.white : Colors.white54,
                        size: 26,
                      ),
                      if (hasItems)
                        Positioned(
                          right: -2,
                          top: -2,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 2,
                            ),
                            constraints: const BoxConstraints(minWidth: 18),
                            decoration: BoxDecoration(
                              color: AppColors.error,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppStyles.cartBarBg, width: 1.5),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              itemCount > 99 ? '99+' : '$itemCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        hasItems ? (cartTitle ?? '购物车') : '尚未选购',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.72),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        hasItems
                            ? '${Money.formatYuan(totalYuan)} · $itemCount 件'
                            : '点击菜品右侧 + 添加',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                FilledButton(
                  onPressed: hasItems ? onCheckout : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    disabledBackgroundColor: Colors.white24,
                    foregroundColor: AppColors.primary,
                    disabledForegroundColor: Colors.white54,
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    checkoutLabel,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
