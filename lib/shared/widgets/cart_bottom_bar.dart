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
  });

  final int itemCount;
  final double totalYuan;
  final VoidCallback? onTap;
  final VoidCallback? onCheckout;

  @override
  Widget build(BuildContext context) {
    final hasItems = itemCount > 0;
    return Material(
      elevation: 12,
      shadowColor: Colors.black26,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(AppStyles.radiusXl)),
      color: AppStyles.cartBarBg,
      child: SafeArea(
        top: false,
        child: InkWell(
          onTap: hasItems ? onTap : null,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppStyles.radiusXl)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: hasItems
                      ? AppColors.primary
                      : Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      Icons.shopping_bag_outlined,
                      color: hasItems ? Colors.white : Colors.white54,
                      size: 24,
                    ),
                    if (hasItems)
                      Positioned(
                        right: -4,
                        top: -4,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          constraints: const BoxConstraints(minWidth: 18),
                          decoration: const BoxDecoration(
                            color: AppColors.error,
                            shape: BoxShape.circle,
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
                      hasItems ? '购物车' : '尚未选购',
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
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor: Colors.white24,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('去结算'),
              ),
            ],
            ),
          ),
        ),
      ),
    );
  }
}
