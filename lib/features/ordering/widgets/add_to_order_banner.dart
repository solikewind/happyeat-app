import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/providers/app_providers.dart';

/// 加菜模式顶栏：展示目标订单，可退出
class AddToOrderBanner extends ConsumerWidget {
  const AddToOrderBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(addToOrderProvider);
    if (session == null) return const SizedBox.shrink();

    return Material(
      color: const Color(0xFFFFF7ED),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
        child: Row(
          children: [
            const Icon(Icons.add_circle_outline, color: Color(0xFFC2410C), size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '加菜模式',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: Color(0xFFC2410C),
                    ),
                  ),
                  Text(
                    session.headline,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    '原单 ${session.existingItemCount} 件 · 购物车仅统计新增',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () => clearOrderingSession(ref),
              child: const Text('退出'),
            ),
          ],
        ),
      ),
    );
  }
}
