import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/money.dart';
import '../../shared/providers/app_providers.dart';
import '../../shared/utils/sales_stats.dart';
import '../../shared/widgets/load_error_panel.dart';

class SalesStatsPage extends ConsumerStatefulWidget {
  const SalesStatsPage({super.key});

  @override
  ConsumerState<SalesStatsPage> createState() => _SalesStatsPageState();
}

class _SalesStatsPageState extends ConsumerState<SalesStatsPage> {
  SalesOverview? _overview;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final overview = await ref.read(statsRepositoryProvider).loadSalesOverview();
      if (mounted) setState(() => _overview = overview);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final overview = _overview;
    return Scaffold(
      appBar: AppBar(title: const Text('经营统计')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? LoadErrorPanel(message: _error!, onRetry: _load)
          : overview == null
          ? const Center(child: Text('暂无数据'))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  _TodayStatsCard(today: overview.today),
                  const SizedBox(height: 12),
                  Card(
                    child: ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.restaurant_menu,
                          color: AppColors.primary,
                        ),
                      ),
                      title: const Text(
                        '菜品销量明细',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        '共 ${overview.menuBreakdown.length} 种菜品 · 今日',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/sales-stats/menus'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '统计范围：今日 0 点至今，已支付/制作中/已完成订单',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _TodayStatsCard extends StatelessWidget {
  const _TodayStatsCard({required this.today});

  final DailySalesPoint today;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateLabel =
        '${now.month}月${now.day}日 · 今日 0 点至今';

    return Card(
      color: AppColors.primary,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    dateLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              Money.formatYuan(today.revenue),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w800,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              '今日营业额',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _TodayMetric(
                  label: '订单',
                  value: '${today.orderCount}',
                ),
                const SizedBox(width: 24),
                _TodayMetric(
                  label: '售出份数',
                  value: '${today.itemCount}',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TodayMetric extends StatelessWidget {
  const _TodayMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }
}
