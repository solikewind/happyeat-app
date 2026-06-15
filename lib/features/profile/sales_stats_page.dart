import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/money.dart';
import '../../shared/providers/app_providers.dart';
import '../../shared/utils/sales_stats.dart';
import '../../shared/utils/stats_range.dart';
import '../../shared/widgets/load_error_panel.dart';

class SalesStatsPage extends ConsumerStatefulWidget {
  const SalesStatsPage({super.key});

  @override
  ConsumerState<SalesStatsPage> createState() => _SalesStatsPageState();
}

class _SalesStatsPageState extends ConsumerState<SalesStatsPage> {
  StatsRangePreset _preset = StatsRangePreset.today;
  DateTimeRange? _customRange;
  StatsRange _range = StatsRange.resolve(StatsRangePreset.today);
  SalesOverview? _overview;
  bool _loading = true;
  String? _error;

  bool get _showDayDetail => _range.startDate == _range.endDate;

  String get _highlightCaption {
    if (_preset == StatsRangePreset.today) return '今日 0 点至今';
    if (_preset == StatsRangePreset.yesterday) return '昨日全天';
    return _range.displayRange;
  }

  DateTime _dateFromRangeString(String value) {
    final parts = value.split('-');
    if (parts.length != 3) return DateTime.now();
    return DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _syncRange() {
    if (_preset == StatsRangePreset.custom) {
      if (_customRange == null) return;
      _range = StatsRange.resolve(
        _preset,
        customStart: _customRange!.start,
        customEnd: _customRange!.end,
      );
      return;
    }
    _range = StatsRange.resolve(_preset);
  }

  Future<void> _load() async {
    if (_preset == StatsRangePreset.custom && _customRange == null) return;
    _syncRange();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final overview = await ref.read(statsRepositoryProvider).loadSalesOverview(
        startDate: _range.startDate,
        endDate: _range.endDate,
      );
      if (mounted) setState(() => _overview = overview);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _selectPreset(StatsRangePreset preset) async {
    if (preset == StatsRangePreset.custom) {
      await _pickCustomRange();
      return;
    }
    if (_preset == preset) return;
    setState(() => _preset = preset);
    await _load();
  }

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    var start = _dateFromRangeString(_range.startDate);
    var end = _dateFromRangeString(_range.endDate);
    var pickingStart = true;

    final picked = await showModalBottomSheet<DateTimeRange>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final active = pickingStart ? start : end;
            return SafeArea(
              child: SizedBox(
                height: 420,
                child: Column(
                  children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '筛选日期',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: _DatePickChip(
                              label: '开始',
                              value: StatsRange.formatChinese(
                                StatsRange.formatDate(start),
                              ),
                              selected: pickingStart,
                              onTap: () => setSheetState(() => pickingStart = true),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _DatePickChip(
                              label: '结束',
                              value: StatsRange.formatChinese(
                                StatsRange.formatDate(end),
                              ),
                              selected: !pickingStart,
                              onTap: () => setSheetState(() => pickingStart = false),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: CalendarDatePicker(
                        initialDate: active,
                        firstDate: DateTime(now.year - 2),
                        lastDate: now,
                        onDateChanged: (date) {
                          setSheetState(() {
                            if (pickingStart) {
                              start = date;
                              if (end.isBefore(start)) end = start;
                            } else {
                              end = date;
                              if (start.isAfter(end)) start = end;
                            }
                          });
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(sheetContext),
                              child: const Text('取消'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton(
                              onPressed: () => Navigator.pop(
                                sheetContext,
                                DateTimeRange(start: start, end: end),
                              ),
                              child: const Text('确定'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (!mounted || picked == null) return;
    setState(() {
      _preset = StatsRangePreset.custom;
      _customRange = picked;
    });
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final overview = _overview;
    return Scaffold(
      appBar: AppBar(
        title: const Text('订单统计'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _load,
          ),
        ],
      ),
      body: _loading && overview == null
          ? const Center(child: CircularProgressIndicator())
          : _error != null && overview == null
          ? LoadErrorPanel(message: _error!, onRetry: _load)
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  _RangeFilterBar(
                    preset: _preset,
                    startDate: _range.startDate,
                    endDate: _range.endDate,
                    onPresetSelected: _selectPreset,
                    onDateBarTap: _pickCustomRange,
                  ),
                  const SizedBox(height: 12),
                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (overview == null)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 48),
                      child: Center(child: Text('暂无数据')),
                    )
                  else ...[
                    _SummaryRow(overview: overview),
                    if (_showDayDetail) ...[
                      const SizedBox(height: 12),
                      _HighlightCard(
                        point: overview.today,
                        caption: _highlightCaption,
                      ),
                      const SizedBox(height: 12),
                      _MenuSalesSection(
                        rows: overview.menuBreakdown,
                        showHeader: true,
                      ),
                    ] else ...[
                      const SizedBox(height: 12),
                      _TrendCard(
                        label: '${_range.label}订单趋势',
                        points: overview.dailyPoints,
                        totalOrders: overview.totalOrders,
                      ),
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
                          subtitle: Text('${overview.menuBreakdown.length} 种菜品'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => context.push(
                            '/sales-stats/menus',
                            extra: _range,
                          ),
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
    );
  }
}

class _RangeFilterBar extends StatelessWidget {
  const _RangeFilterBar({
    required this.preset,
    required this.startDate,
    required this.endDate,
    required this.onPresetSelected,
    required this.onDateBarTap,
  });

  final StatsRangePreset preset;
  final String startDate;
  final String endDate;
  final ValueChanged<StatsRangePreset> onPresetSelected;
  final VoidCallback onDateBarTap;

  static const presets = <(StatsRangePreset, String)>[
    (StatsRangePreset.today, '今天'),
    (StatsRangePreset.yesterday, '昨天'),
    (StatsRangePreset.last7d, '近七天'),
    (StatsRangePreset.last30d, '30天'),
  ];

  @override
  Widget build(BuildContext context) {
    final startLabel = StatsRange.formatChinese(startDate);
    final endLabel = StatsRange.formatChinese(endDate);
    final isSingleDay = startDate == endDate;
    final isCustom = preset == StatsRangePreset.custom;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (var i = 0; i < presets.length; i++) ...[
                if (i > 0) const _RangeLinkSeparator(),
                _RangeLink(
                  label: presets[i].$2,
                  selected: preset == presets[i].$1,
                  onTap: () => onPresetSelected(presets[i].$1),
                ),
              ],
              const _RangeLinkSeparator(),
              _RangeLink(
                label: '筛选日期',
                selected: isCustom,
                onTap: () => onPresetSelected(StatsRangePreset.custom),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Material(
          color: isCustom ? AppColors.primaryLight : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: onDateBarTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isCustom
                      ? AppColors.primary.withValues(alpha: 0.45)
                      : const Color(0xFFCBD5E1),
                  width: isCustom ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.date_range_outlined,
                    size: 18,
                    color: isCustom ? AppColors.primary : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: isSingleDay
                        ? Text(
                            startLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.2,
                              color: isCustom
                                  ? AppColors.primary
                                  : const Color(0xFF1E293B),
                            ),
                          )
                        : Row(
                            children: [
                              Expanded(
                                child: Text(
                                  startLabel,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: isCustom
                                        ? AppColors.primary
                                        : const Color(0xFF1E293B),
                                  ),
                                ),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8),
                                child: Text(
                                  '至',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary
                                        .withValues(alpha: 0.8),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  endLabel,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.end,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: isCustom
                                        ? AppColors.primary
                                        : const Color(0xFF1E293B),
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                  Icon(
                    Icons.edit_outlined,
                    size: 16,
                    color: AppColors.primary.withValues(alpha: 0.7),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RangeLinkSeparator extends StatelessWidget {
  const _RangeLinkSeparator();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Text(
        '|',
        style: TextStyle(
          fontSize: 13,
          color: AppColors.textSecondary.withValues(alpha: 0.35),
          height: 1.2,
        ),
      ),
    );
  }
}

class _RangeLink extends StatelessWidget {
  const _RangeLink({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _DatePickChip extends StatelessWidget {
  const _DatePickChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String value;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryLight : const Color(0xFFF5F7FA),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppColors.primary : Colors.transparent,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: selected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? AppColors.primary : const Color(0xFF101828),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuSalesSection extends StatelessWidget {
  const _MenuSalesSection({
    required this.rows,
    this.showHeader = false,
  });

  final List<MenuSalesRow> rows;
  final bool showHeader;

  @override
  Widget build(BuildContext context) {
    final totalQty = rows.fold<int>(0, (sum, e) => sum + e.quantity);
    final totalAmount = rows.fold<double>(0, (sum, e) => sum + e.amount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showHeader)
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text(
              '菜品销量明细',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
          ),
        if (rows.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: Text('今日暂无售出记录')),
            ),
          )
        else ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Expanded(
                    child: _MiniStat(label: '售出', value: '$totalQty 份'),
                  ),
                  Expanded(
                    child: _MiniStat(
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
          ...rows.asMap().entries.map((entry) {
            final index = entry.key;
            final row = entry.value;
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                dense: true,
                leading: CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.primaryLight,
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
                title: Text(
                  row.menuName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                subtitle: row.displaySpec.isEmpty ? null : Text(row.displaySpec),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '×${row.quantity}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      Money.formatYuan(row.amount),
                      style: const TextStyle(
                        color: AppColors.error,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
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
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: emphasized ? AppColors.error : const Color(0xFF101828),
          ),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.overview});

  final SalesOverview overview;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            title: '营业额',
            value: Money.formatYuan(overview.totalRevenue),
            color: const Color(0xFF1677FF),
            bg: const Color(0xFFE6F4FF),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SummaryCard(
            title: '有效订单',
            value: '${overview.totalOrders}单',
            color: const Color(0xFFD48806),
            bg: const Color(0xFFFFF7E6),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SummaryCard(
            title: '售出份数',
            value: '${overview.totalItems}份',
            color: const Color(0xFF389E0D),
            bg: const Color(0xFFF6FFED),
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.value,
    required this.color,
    required this.bg,
  });

  final String title;
  final String value;
  final Color color;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: bg,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 12, color: color.withValues(alpha: 0.85)),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HighlightCard extends StatelessWidget {
  const _HighlightCard({
    required this.point,
    required this.caption,
  });

  final DailySalesPoint point;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.primary,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              caption,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Text(
              Money.formatYuan(point.revenue),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _HighlightMetric(label: '订单', value: '${point.orderCount}'),
                const SizedBox(width: 24),
                _HighlightMetric(label: '份数', value: '${point.itemCount}'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HighlightMetric extends StatelessWidget {
  const _HighlightMetric({required this.label, required this.value});

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
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }
}

class _TrendCard extends StatelessWidget {
  const _TrendCard({
    required this.label,
    required this.points,
    required this.totalOrders,
  });

  final String label;
  final List<DailySalesPoint> points;
  final int totalOrders;

  @override
  Widget build(BuildContext context) {
    final maxOrders = points.fold<int>(
      1,
      (max, p) => p.orderCount > max ? p.orderCount : max,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
                Text(
                  '合计 $totalOrders 单',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (points.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: Text('该时段暂无订单')),
              )
            else
              SizedBox(
                height: 160,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: points.map((point) {
                      final ratio = point.orderCount / maxOrders;
                      final barHeight = 80.0 * (ratio < 0.08 ? 0.08 : ratio);
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: SizedBox(
                          width: 44,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                '${point.orderCount}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                width: 28,
                                height: barHeight,
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                point.label,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
