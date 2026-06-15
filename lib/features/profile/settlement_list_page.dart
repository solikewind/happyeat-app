import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/money.dart';
import '../../data/models/models.dart';
import '../../shared/providers/app_providers.dart';
import '../../shared/utils/settlement_display.dart';
import '../../shared/widgets/brief_snack_bar.dart';
import '../../shared/widgets/load_error_panel.dart';

const _pageSize = 15;

class SettlementListPage extends ConsumerStatefulWidget {
  const SettlementListPage({super.key});

  @override
  ConsumerState<SettlementListPage> createState() => _SettlementListPageState();
}

class _SettlementListPageState extends ConsumerState<SettlementListPage> {
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  Timer? _searchDebounce;

  String _statusTab = 'UNSETTLED';
  String _customerQuery = '';
  List<SettlementModel> _settlements = [];
  int _page = 1;
  int _total = 0;
  bool _loading = false;
  bool _loadingMore = false;
  String? _error;
  bool _creating = false;
  String? _deletingId;

  bool get _hasMore => _settlements.length < _total;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    _load(reset: true);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_hasMore || _loading || _loadingMore) return;
    if (_scrollCtrl.position.pixels <
        _scrollCtrl.position.maxScrollExtent - 120) {
      return;
    }
    _loadMore();
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      final next = value.trim();
      if (next == _customerQuery) return;
      _customerQuery = next;
      _load(reset: true);
    });
  }

  Future<void> _load({required bool reset}) async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
      if (reset) {
        _page = 1;
        _settlements = [];
        _total = 0;
      }
    });
    try {
      final result = await ref.read(settlementRepositoryProvider).listSettlements(
        current: 1,
        pageSize: _pageSize,
        status: _statusTab,
        customerName: _customerQuery.isEmpty ? null : _customerQuery,
      );
      if (mounted) {
        setState(() {
          _page = 1;
          _settlements = result.settlements;
          _total = result.total;
        });
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);
    final nextPage = _page + 1;
    try {
      final result = await ref.read(settlementRepositoryProvider).listSettlements(
        current: nextPage,
        pageSize: _pageSize,
        status: _statusTab,
        customerName: _customerQuery.isEmpty ? null : _customerQuery,
      );
      if (!mounted) return;
      final existing = _settlements.map((e) => e.id).toSet();
      setState(() {
        _page = nextPage;
        _total = result.total;
        _settlements = [
          ..._settlements,
          ...result.settlements.where((e) => !existing.contains(e.id)),
        ];
      });
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  Future<void> _deleteSettlement(SettlementModel settlement) async {
    if (!settlement.isUnsettled || _deletingId != null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除结账单'),
        content: Text(
          settlement.orderCount > 0
              ? '将删除「${settlement.customerName}」的结账单，关联 ${settlement.orderCount} 笔订单会自动解绑，确定继续？'
              : '确定删除「${settlement.customerName}」的空结账单？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _deletingId = settlement.id);
    try {
      await ref.read(settlementRepositoryProvider).deleteSettlement(settlement.id);
      if (!mounted) return;
      showBriefSnackBar(context, '结账单已删除');
      await _load(reset: true);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } finally {
      if (mounted) setState(() => _deletingId = null);
    }
  }

  Future<void> _createSettlement() async {
    final nameCtrl = TextEditingController();
    final remarkCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('新建结账单'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: '客户名称',
                hintText: '如：张三、大厅常客',
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: remarkCtrl,
              decoration: const InputDecoration(
                labelText: '备注（可选）',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('创建'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final name = nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请填写客户名称')),
      );
      return;
    }

    setState(() => _creating = true);
    try {
      final created = await ref.read(settlementRepositoryProvider).createSettlement(
        customerName: name,
        remark: remarkCtrl.text.trim(),
      );
      if (!mounted) return;
      setState(() => _statusTab = 'UNSETTLED');
      await _load(reset: true);
      if (!mounted) return;
      await context.push('/settlements/${created.id}');
      if (mounted) await _load(reset: true);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('结账单'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : () => _load(reset: true),
          ),
        ],
      ),
      floatingActionButton: _statusTab == 'UNSETTLED'
          ? FloatingActionButton.extended(
              onPressed: _creating ? null : _createSettlement,
              icon: _creating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.add),
              label: const Text('新建'),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'UNSETTLED', label: Text('未结账')),
                ButtonSegment(value: 'SETTLED', label: Text('已结账')),
              ],
              selected: {_statusTab},
              onSelectionChanged: (value) {
                if (value.isEmpty) return;
                setState(() => _statusTab = value.first);
                _load(reset: true);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: '搜索客户名称',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _customerQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          _customerQuery = '';
                          _load(reset: true);
                        },
                      )
                    : null,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
              textInputAction: TextInputAction.search,
              onChanged: _onSearchChanged,
              onSubmitted: (value) {
                _searchDebounce?.cancel();
                _customerQuery = value.trim();
                _load(reset: true);
              },
            ),
          ),
          Expanded(
            child: _loading && _settlements.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _error != null && _settlements.isEmpty
                ? LoadErrorPanel(
                    message: _error!,
                    onRetry: () => _load(reset: true),
                  )
                : _settlements.isEmpty
                ? Center(
                    child: Text(
                      _customerQuery.isEmpty ? '暂无结账单' : '未找到匹配客户',
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () => _load(reset: true),
                    child: ListView.separated(
                      controller: _scrollCtrl,
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      itemCount:
                          _settlements.length + (_loadingMore ? 1 : 0),
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        if (index >= _settlements.length) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Center(
                              child: SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                          );
                        }
                        final item = _settlements[index];
                        return _SettlementListTile(
                          settlement: item,
                          deleting: _deletingId == item.id,
                          onTap: () async {
                            await context.push('/settlements/${item.id}');
                            if (mounted) await _load(reset: true);
                          },
                          onDelete: item.isUnsettled
                              ? () => _deleteSettlement(item)
                              : null,
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _SettlementListTile extends StatelessWidget {
  const _SettlementListTile({
    required this.settlement,
    required this.onTap,
    this.onDelete,
    this.deleting = false,
  });

  final SettlementModel settlement;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final bool deleting;

  @override
  Widget build(BuildContext context) {
    final unsettled = settlement.isUnsettled;
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      settlement.customerName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _StatusChip(
                          label: SettlementDisplay.statusLabel(settlement.status),
                          color: unsettled ? AppColors.warning : AppColors.success,
                        ),
                        Text(
                          '${settlement.orderCount} 单',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                        if (settlement.createdAt != null)
                          Text(
                            SettlementDisplay.formatDateTime(settlement.createdAt) ??
                                '',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    Money.formatYuan(settlement.totalAmount),
                    style: TextStyle(
                      color: unsettled ? AppColors.error : AppColors.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                  if (!unsettled)
                    Text(
                      '实收 ${Money.formatYuan(settlement.actualAmount)}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
              if (onDelete != null)
                deleting
                    ? const Padding(
                        padding: EdgeInsets.all(8),
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : IconButton(
                        onPressed: onDelete,
                        icon: const Icon(Icons.delete_outline),
                        color: AppColors.error,
                        tooltip: '删除',
                      )
              else
                const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
