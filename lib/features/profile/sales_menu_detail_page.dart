import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/money.dart';
import '../../shared/providers/app_providers.dart';
import '../../shared/utils/sales_stats.dart';
import '../../shared/utils/stats_range.dart';
import '../../shared/widgets/load_error_panel.dart';

class SalesMenuDetailPage extends ConsumerStatefulWidget {
  const SalesMenuDetailPage({super.key, required this.range});

  final StatsRange range;

  @override
  ConsumerState<SalesMenuDetailPage> createState() =>
      _SalesMenuDetailPageState();
}

class _SalesMenuDetailPageState extends ConsumerState<SalesMenuDetailPage> {
  List<MenuSalesRow> _rows = [];
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
      final overview = await ref.read(statsRepositoryProvider).loadSalesOverview(
        startDate: widget.range.startDate,
        endDate: widget.range.endDate,
      );
      if (mounted) setState(() => _rows = overview.menuBreakdown);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalQty = _rows.fold<int>(0, (sum, e) => sum + e.quantity);
    final totalAmount = _rows.fold<double>(0, (sum, e) => sum + e.amount);

    return Scaffold(
      appBar: AppBar(title: const Text('菜品销量明细')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? LoadErrorPanel(message: _error!, onRetry: _load)
          : _rows.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Text(
                    widget.range.displayRange,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 120),
                const Center(child: Text('该时段暂无售出记录')),
              ],
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    widget.range.displayRange,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: _TotalBlock(
                              label: '售出',
                              value: '$totalQty 份',
                            ),
                          ),
                          Expanded(
                            child: _TotalBlock(
                              label: '金额',
                              value: Money.formatYuan(totalAmount),
                              emphasized: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ..._rows.asMap().entries.map((entry) {
                    final index = entry.key;
                    final row = entry.value;
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primaryLight,
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        title: Text(
                          row.menuName,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: row.displaySpec.isEmpty
                            ? null
                            : Text(row.displaySpec),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '×${row.quantity}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              Money.formatYuan(row.amount),
                              style: const TextStyle(
                                color: AppColors.error,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
    );
  }
}

class _TotalBlock extends StatelessWidget {
  const _TotalBlock({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: emphasized ? AppColors.error : const Color(0xFF101828),
          ),
        ),
      ],
    );
  }
}
