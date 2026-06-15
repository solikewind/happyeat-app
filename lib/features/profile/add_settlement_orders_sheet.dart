import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/money.dart';
import '../../data/models/models.dart';
import '../../shared/providers/app_providers.dart';
import '../../shared/widgets/brief_snack_bar.dart';
import '../../shared/widgets/order_status_chip.dart';

const _pageSize = 10;

/// 从结账单详情添加订单。
class AddSettlementOrdersSheet extends ConsumerStatefulWidget {
  const AddSettlementOrdersSheet({
    super.key,
    required this.settlementId,
    this.preselectedOrderId,
    this.onAdded,
  });

  final String settlementId;
  final String? preselectedOrderId;
  final void Function(SettlementModel settlement)? onAdded;

  @override
  ConsumerState<AddSettlementOrdersSheet> createState() =>
      _AddSettlementOrdersSheetState();
}

class _AddSettlementOrdersSheetState
    extends ConsumerState<AddSettlementOrdersSheet> {
  final _searchCtrl = TextEditingController();
  Timer? _searchDebounce;

  List<OrderModel> _orders = [];
  final Set<String> _selectedIds = {};
  bool _loading = false;
  bool _submitting = false;
  String? _error;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    if (widget.preselectedOrderId != null) {
      _selectedIds.add(widget.preselectedOrderId!);
    }
    _load();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  bool _isAddable(OrderModel order) {
    if (order.status == 'cancelled') return false;
    final sid = order.settlementId;
    if (sid != null && sid.isNotEmpty) return false;
    return true;
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      final next = value.trim();
      if (next == _searchQuery) return;
      _searchQuery = next;
      _load();
    });
  }

  Future<void> _load() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
      _orders = [];
    });
    try {
      final result = await ref.read(orderRepositoryProvider).listOrders(
        current: 1,
        pageSize: _pageSize,
        orderNo: _searchQuery.isEmpty ? null : _searchQuery,
      );
      if (!mounted) return;
      final addable = result.orders.where(_isAddable).toList();
      setState(() => _orders = addable);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    if (_selectedIds.isEmpty || _submitting) return;
    setState(() => _submitting = true);
    SettlementModel? updated;
    try {
      for (final orderId in _selectedIds) {
        updated = await ref.read(settlementRepositoryProvider).addOrder(
          settlementId: widget.settlementId,
          orderId: orderId,
        );
      }
      if (!mounted || updated == null) return;
      showBriefSnackBar(context, '已加入 ${_selectedIds.length} 笔订单');
      widget.onAdded?.call(updated);
      Navigator.pop(context, updated);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final hint = _searchQuery.isEmpty
        ? '默认展示最近 $_pageSize 笔可加入订单，可按订单号搜索'
        : '搜索「$_searchQuery」，最多 $_pageSize 笔';

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + bottom),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '选择订单',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: '搜索订单号',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          _searchQuery = '';
                          _load();
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
                _searchQuery = value.trim();
                _load();
              },
            ),
            const SizedBox(height: 6),
            Text(
              hint,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _loading && _orders.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null && _orders.isEmpty
                  ? Center(child: Text(_error!))
                  : _orders.isEmpty
                  ? Center(
                      child: Text(
                        _searchQuery.isEmpty ? '暂无可加入的订单' : '未找到匹配订单',
                      ),
                    )
                  : ListView.separated(
                      itemCount: _orders.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 6),
                      itemBuilder: (context, index) {
                        final order = _orders[index];
                        final selected = _selectedIds.contains(order.id);
                        return _SettlementOrderPickTile(
                          order: order,
                          selected: selected,
                          onTap: () {
                            setState(() {
                              if (selected) {
                                _selectedIds.remove(order.id);
                              } else {
                                _selectedIds.add(order.id);
                              }
                            });
                          },
                        );
                      },
                    ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _submitting || _selectedIds.isEmpty ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text('加入 ${_selectedIds.length} 笔订单'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettlementOrderPickTile extends StatelessWidget {
  const _SettlementOrderPickTile({
    required this.order,
    required this.selected,
    required this.onTap,
  });

  final OrderModel order;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final itemCount = order.items.fold<int>(0, (sum, e) => sum + e.quantity);
    final isDineIn = order.orderType == 'dine_in';
    final accent = isDineIn ? AppColors.primary : AppColors.warning;

    return Material(
      color: selected ? AppColors.primaryLight : const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected
                  ? AppColors.primary.withValues(alpha: 0.45)
                  : const Color(0xFFE2E8F0),
            ),
          ),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.check_circle
                    : Icons.radio_button_unchecked,
                size: 20,
                color: selected ? AppColors.primary : AppColors.textSecondary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isDineIn
                              ? Icons.table_restaurant_outlined
                              : Icons.takeout_dining,
                          size: 16,
                          color: accent,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            order.locationLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: accent,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        Text(
                          Money.formatYuan(order.totalAmount),
                          style: const TextStyle(
                            color: AppColors.error,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 2,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          order.orderNo,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        OrderStatusChip(status: order.status),
                        if (itemCount > 0)
                          Text(
                            '$itemCount 件',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        if (order.createdAtLabel != null)
                          Text(
                            order.createdAtLabel!,
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
            ],
          ),
        ),
      ),
    );
  }
}

/// 订单详情页：将当前订单加入结账单。
Future<bool?> showAddOrderToSettlementSheet(
  BuildContext context, {
  required OrderModel order,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => _AddOrderToSettlementSheet(order: order),
  );
}

class _AddOrderToSettlementSheet extends ConsumerStatefulWidget {
  const _AddOrderToSettlementSheet({required this.order});

  final OrderModel order;

  @override
  ConsumerState<_AddOrderToSettlementSheet> createState() =>
      _AddOrderToSettlementSheetState();
}

class _AddOrderToSettlementSheetState
    extends ConsumerState<_AddOrderToSettlementSheet> {
  final _searchCtrl = TextEditingController();
  Timer? _searchDebounce;

  List<SettlementModel> _settlements = [];
  bool _loading = true;
  bool _submitting = false;
  String? _error;
  String _customerQuery = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      final next = value.trim();
      if (next == _customerQuery) return;
      _customerQuery = next;
      _load();
    });
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await ref.read(settlementRepositoryProvider).listSettlements(
        status: 'UNSETTLED',
        pageSize: 20,
        customerName: _customerQuery.isEmpty ? null : _customerQuery,
      );
      if (mounted) setState(() => _settlements = result.settlements);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _addToSettlement(SettlementModel settlement) async {
    if (_submitting) return;
    setState(() => _submitting = true);
    try {
      await ref.read(settlementRepositoryProvider).addOrder(
        settlementId: settlement.id,
        orderId: widget.order.id,
      );
      if (!mounted) return;
      showBriefSnackBar(context, '已加入结账单');
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _createAndAdd() async {
    if (_submitting) return;
    final nameCtrl = TextEditingController(text: widget.order.locationLabel);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('新建结账单'),
        content: TextField(
          controller: nameCtrl,
          decoration: const InputDecoration(labelText: '客户名称'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('创建并加入'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final name = nameCtrl.text.trim();
    if (name.isEmpty) return;

    setState(() => _submitting = true);
    try {
      final created = await ref.read(settlementRepositoryProvider).createSettlement(
        customerName: name,
      );
      await ref.read(settlementRepositoryProvider).addOrder(
        settlementId: created.id,
        orderId: widget.order.id,
      );
      if (!mounted) return;
      showBriefSnackBar(context, '已创建结账单并加入订单');
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final order = widget.order;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '加入结账单',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            _SettlementOrderPickTile(
              order: order,
              selected: true,
              onTap: () {},
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _submitting ? null : _createAndAdd,
              icon: const Icon(Icons.add),
              label: const Text('新建结账单并加入'),
            ),
            const SizedBox(height: 12),
            TextField(
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
                          _load();
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
                _load();
              },
            ),
            const SizedBox(height: 12),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(_error!, textAlign: TextAlign.center),
              )
            else if (_settlements.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  _customerQuery.isEmpty ? '暂无未结账结账单，请新建' : '未找到匹配客户',
                  textAlign: TextAlign.center,
                ),
              )
            else ...[
              const Text(
                '选择已有结账单',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.35,
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _settlements.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 6),
                  itemBuilder: (context, index) {
                    final item = _settlements[index];
                    return Material(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      child: ListTile(
                        dense: true,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        title: Text(
                          item.customerName,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          '${item.orderCount} 单 · ${Money.formatYuan(item.totalAmount)}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: _submitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.chevron_right, size: 20),
                        onTap: _submitting ? null : () => _addToSettlement(item),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
