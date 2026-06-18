import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class OrderDailySequenceChip extends StatelessWidget {
  const OrderDailySequenceChip({super.key, required this.sequence});

  final int sequence;

  @override
  Widget build(BuildContext context) {
    if (sequence <= 0) {
      return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '第$sequence单',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
      ),
    );
  }
}
