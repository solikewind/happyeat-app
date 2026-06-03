import 'package:flutter/material.dart';

import '../../../core/theme/app_styles.dart';
import '../../../core/theme/app_theme.dart';

/// 点餐页顶部：品牌 + 搜索
class OrderingHeader extends StatelessWidget {
  const OrderingHeader({
    super.key,
    required this.onSearchChanged,
  });

  final ValueChanged<String> onSearchChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4096FF), AppColors.primary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: const Text(
                  'H',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('快乐餐厅', style: AppStyles.pageTitle),
                    Text('点餐台', style: AppStyles.pageSubtitle),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SearchBar(
            hintText: '搜索菜品名称',
            leading: Icon(Icons.search, color: AppColors.textSecondary.withValues(alpha: 0.8)),
            backgroundColor: WidgetStateProperty.all(AppStyles.surfaceMuted),
            elevation: WidgetStateProperty.all(0),
            shape: WidgetStateProperty.all(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppStyles.radiusMd),
                side: const BorderSide(color: AppStyles.border),
              ),
            ),
            padding: const WidgetStatePropertyAll(
              EdgeInsets.symmetric(horizontal: 12),
            ),
            onChanged: onSearchChanged,
          ),
        ],
      ),
    );
  }
}
