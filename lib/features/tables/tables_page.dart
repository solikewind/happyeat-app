import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_styles.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/models.dart';
import '../../data/models/table_category.dart';
import '../../shared/providers/app_providers.dart';
import '../../shared/utils/order_status_display.dart';
import '../../shared/utils/table_display.dart';
import '../../shared/widgets/load_error_panel.dart';
import 'widgets/table_detail_sheet.dart';
import 'widgets/table_floor_tile.dart';

/// 厅面看板：展示桌台状态与进行中订单（不负责选桌，选桌在点餐页）
class TablesPage extends ConsumerStatefulWidget {
  const TablesPage({super.key});

  @override
  ConsumerState<TablesPage> createState() => _TablesPageState();
}

class _TablesPageState extends ConsumerState<TablesPage> {
  List<TableItem> _tables = [];
  List<TableCategoryItem> _categories = [];
  List<OrderModel> _activeOrders = [];
  String? _statusFilter;
  bool _loading = true;
  String? _error;
  Timer? _autoRefresh;

  @override
  void initState() {
    super.initState();
    _load();
    _autoRefresh = Timer.periodic(const Duration(seconds: 45), (_) {
      if (mounted) _load(silent: true);
    });
  }

  @override
  void dispose() {
    _autoRefresh?.cancel();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final tableRepo = ref.read(tableRepositoryProvider);
      final orderRepo = ref.read(orderRepositoryProvider);
      final results = await Future.wait([
        tableRepo.listTables(),
        tableRepo.listTableCategories(),
        orderRepo.listOrders(pageSize: 500),
      ]);
      if (!mounted) return;
      final tables = results[0] as List<TableItem>;
      final categories = results[1] as List<TableCategoryItem>;
      final orderRes = results[2] as ({List<OrderModel> orders, int total});
      final active = orderRes.orders
          .where((o) =>
              o.tableId != null &&
              o.tableId!.isNotEmpty &&
              OrderStatusDisplay.isActive(o.status))
          .toList();

      setState(() {
        _tables = tables;
        _categories = categories;
        _activeOrders = active;
        _error = null;
      });
    } on ApiException catch (e) {
      if (mounted && !silent) setState(() => _error = e.message);
    } finally {
      if (mounted && !silent) setState(() => _loading = false);
    }
  }

  Map<String, String> get _categoryNameById {
    return {for (final c in _categories) c.id: c.name};
  }

  List<TableItem> get _filteredTables {
    if (_statusFilter == null || _statusFilter!.isEmpty) return _tables;
    return _tables
        .where((t) => t.status.toLowerCase() == _statusFilter!.toLowerCase())
        .toList();
  }

  Map<String, List<TableItem>> get _groupedTables {
    final map = <String, List<TableItem>>{};
    for (final t in _filteredTables) {
      final name = _categoryNameById[t.categoryId];
      final key = (name != null && name.isNotEmpty) ? name : '未分类';
      map.putIfAbsent(key, () => []).add(t);
    }
    for (final list in map.values) {
      list.sort((a, b) => a.code.compareTo(b.code));
    }
    return Map.fromEntries(
      map.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );
  }

  int _countByKind(TableStatusKind kind) {
    return _tables.where((t) => TableDisplay.kindOf(t.status) == kind).length;
  }

  List<OrderModel> _ordersForTable(String tableId) {
    return _activeOrders.where((o) => o.tableId == tableId).toList();
  }

  void _openTableDetail(TableItem table) {
    final orders = _ordersForTable(table.id);
    showTableDetailSheet(
      context,
      table: table,
      categoryName: _categoryNameById[table.categoryId],
      activeOrders: orders,
    );
  }

  @override
  Widget build(BuildContext context) {
    final idle = _countByKind(TableStatusKind.idle);
    final using = _countByKind(TableStatusKind.using);
    final reserved = _countByKind(TableStatusKind.reserved);
    final cleaning = _countByKind(TableStatusKind.cleaning);
    final groups = _groupedTables;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('厅面看板', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            Text(
              '查看桌态与进行中订单',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _loading ? null : () => _load(),
            icon: const Icon(Icons.refresh),
            tooltip: '刷新',
          ),
        ],
      ),
      body: _loading && _tables.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _error != null && _tables.isEmpty
              ? LoadErrorPanel(message: _error!, onRetry: () => _load())
              : RefreshIndicator(
                  onRefresh: () => _load(),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    children: [
                      _SummaryStrip(
                        idle: idle,
                        using: using,
                        reserved: reserved,
                        cleaning: cleaning,
                        total: _tables.length,
                      ),
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _StatusFilterChip(
                              label: '全部',
                              selected: _statusFilter == null,
                              onTap: () => setState(() => _statusFilter = null),
                            ),
                            _StatusFilterChip(
                              label: '空闲 $idle',
                              color: TableDisplay.statusColor('idle'),
                              selected: _statusFilter == 'idle',
                              onTap: () => setState(() => _statusFilter = 'idle'),
                            ),
                            _StatusFilterChip(
                              label: '使用中 $using',
                              color: TableDisplay.statusColor('using'),
                              selected: _statusFilter == 'using',
                              onTap: () => setState(() => _statusFilter = 'using'),
                            ),
                            _StatusFilterChip(
                              label: '预留 $reserved',
                              color: TableDisplay.statusColor('reserved'),
                              selected: _statusFilter == 'reserved',
                              onTap: () => setState(() => _statusFilter = 'reserved'),
                            ),
                            _StatusFilterChip(
                              label: '清洁 $cleaning',
                              color: TableDisplay.statusColor('cleaning'),
                              selected: _statusFilter == 'cleaning',
                              onTap: () => setState(() => _statusFilter = 'cleaning'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (groups.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 48),
                          child: Center(
                            child: Text(
                              '没有符合筛选的餐桌',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          ),
                        )
                      else
                        ...groups.entries.map((entry) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Text(
                                  entry.key,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                    color: AppStyles.textPrimary,
                                  ),
                                ),
                              ),
                              GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  mainAxisSpacing: 10,
                                  crossAxisSpacing: 10,
                                  childAspectRatio: 0.92,
                                ),
                                itemCount: entry.value.length,
                                itemBuilder: (context, index) {
                                  final table = entry.value[index];
                                  final orders = _ordersForTable(table.id);
                                  final strongest = orders.isEmpty
                                      ? null
                                      : OrderStatusDisplay.strongestActiveStatus(
                                          orders.map((o) => o.status),
                                        );
                                  return TableFloorTile(
                                    table: table,
                                    activeOrderCount: orders.length,
                                    activeOrderStatus: strongest,
                                    onTap: () => _openTableDetail(table),
                                  );
                                },
                              ),
                              const SizedBox(height: 20),
                            ],
                          );
                        }),
                    ],
                  ),
                ),
    );
  }
}

class _SummaryStrip extends StatelessWidget {
  const _SummaryStrip({
    required this.idle,
    required this.using,
    required this.reserved,
    required this.cleaning,
    required this.total,
  });

  final int idle;
  final int using;
  final int reserved;
  final int cleaning;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AppStyles.surfaceCard(),
      child: Row(
        children: [
          Expanded(
            child: _StatCell(
              label: '总桌数',
              value: '$total',
              color: AppColors.primary,
            ),
          ),
          _divider(),
          Expanded(
            child: _StatCell(
              label: '空闲',
              value: '$idle',
              color: TableDisplay.statusColor('idle'),
            ),
          ),
          _divider(),
          Expanded(
            child: _StatCell(
              label: '使用中',
              value: '$using',
              color: TableDisplay.statusColor('using'),
            ),
          ),
          _divider(),
          Expanded(
            child: _StatCell(
              label: '预留/清洁',
              value: '${reserved + cleaning}',
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Container(
        width: 1,
        height: 36,
        color: AppStyles.border,
        margin: const EdgeInsets.symmetric(horizontal: 6),
      );
}

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _StatusFilterChip extends StatelessWidget {
  const _StatusFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.color,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primary;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: c.withValues(alpha: 0.15),
        checkmarkColor: c,
        labelStyle: TextStyle(
          fontSize: 12,
          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          color: selected ? c : AppColors.textSecondary,
        ),
        side: BorderSide(color: selected ? c : AppStyles.border),
      ),
    );
  }
}
