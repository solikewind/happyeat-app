import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/money.dart';
import '../../data/models/models.dart';
import '../../shared/providers/app_providers.dart';
import '../../shared/utils/add_to_order_flow.dart';
import '../../shared/utils/order_status_display.dart';
import '../../shared/widgets/brief_snack_bar.dart';
import '../../shared/widgets/load_error_panel.dart';
import '../../shared/widgets/order_cancel_dialog.dart';
import '../../shared/widgets/order_detail_action_bar.dart';
import '../../shared/widgets/order_status_chip.dart';
import '../../shared/widgets/order_table_headline.dart';

class OrderDetailPage extends ConsumerStatefulWidget {
  const OrderDetailPage({super.key, required this.orderId});

  final String orderId;

  @override
  ConsumerState<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends ConsumerState<OrderDetailPage> {
  OrderModel? _order;
  bool _loading = true;
  bool _updatingStatus = false;
  bool _printing = false;
  bool _cancelling = false;
  int? _removingItemIndex;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final order = await ref
          .read(orderRepositoryProvider)
          .getOrder(widget.orderId);
      if (mounted) setState(() => _order = order);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted && !silent) setState(() => _loading = false);
    }
  }

  Future<void> _advanceStatus(OrderModel order) async {
    final next = OrderStatusDisplay.workbenchAdvanceTarget(order.status);
    if (next == null || _updatingStatus) return;

    setState(() => _updatingStatus = true);
    try {
      await ref.read(orderRepositoryProvider).updateOrderStatus(order.id, next);
      if (!mounted) return;
      showBriefSnackBar(
        context,
        OrderStatusDisplay.advanceSuccessMessage(next),
      );
      await _load(silent: true);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _updatingStatus = false);
    }
  }

  Future<void> _printKitchen(OrderModel order) async {
    if (_printing) return;
    setState(() => _printing = true);
    try {
      await ref.read(orderRepositoryProvider).printOrderKitchen(order.id);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(
        content: Text('已提交厨房打印'),
        duration: Duration(milliseconds: 1200),
      ));
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _printing = false);
    }
  }

  bool _canPrintKitchen(OrderModel order) {
    return order.status.trim().toLowerCase() != 'cancelled';
  }

  Future<void> _removeItemAt(OrderModel order, int index) async {
    if (_removingItemIndex != null ||
        !OrderStatusDisplay.canAddItems(order.status)) {
      return;
    }
    final item = order.items[index];
    final isLast = order.items.length == 1;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isLast ? '删除最后一道菜' : '删除菜品'),
        content: Text(
          isLast
              ? '「${item.menuName}」是最后一道菜，删除后将取消整单，确定继续？'
              : '确定从订单中删除「${item.menuName}」？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(isLast ? '取消订单' : '删除'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _removingItemIndex = index);
    try {
      if (isLast) {
        await ref.read(orderRepositoryProvider).cancelOrder(order.id);
        if (!mounted) return;
        showBriefSnackBar(context, OrderStatusDisplay.cancelSuccessMessage);
        context.pop();
        return;
      }

      final menus = await ref.read(menuRepositoryProvider).listMenus();
      final menuNameToId = {for (final m in menus) m.name: m.id};
      final remaining = [...order.items]..removeAt(index);
      await ref.read(orderRepositoryProvider).replaceOrderItems(
        orderId: order.id,
        items: remaining,
        menuNameToId: menuNameToId,
      );
      if (!mounted) return;
      showBriefSnackBar(context, '已删除 ${item.menuName}');
      await _load(silent: true);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _removingItemIndex = null);
    }
  }

  Future<void> _removeOrder(OrderModel order) async {
    if (_cancelling || !OrderStatusDisplay.canRemove(order.status)) return;
    final isDelete = OrderStatusDisplay.canDelete(order.status);
    if (!await confirmRemoveOrder(context, isDelete: isDelete)) return;

    setState(() => _cancelling = true);
    try {
      await ref.read(orderRepositoryProvider).cancelOrder(order.id);
      if (!mounted) return;
      showBriefSnackBar(
        context,
        isDelete
            ? OrderStatusDisplay.deleteSuccessMessage
            : OrderStatusDisplay.cancelSuccessMessage,
      );
      context.pop();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _cancelling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = _order;
    final showAdvance =
        order != null &&
        OrderStatusDisplay.workbenchAdvanceTarget(order.status) != null;
    final showPrint = order != null && _canPrintKitchen(order);
    final showAddItems =
        order != null && OrderStatusDisplay.canAddItems(order.status);
    final canEditItems = showAddItems;
    final showRemove =
        order != null && OrderStatusDisplay.canRemove(order.status);
    final showBottomBar =
        showAddItems || showAdvance || showPrint || showRemove;
    return Scaffold(
      appBar: AppBar(title: const Text('订单详情')),
      bottomNavigationBar: showBottomBar
          ? OrderDetailActionBar(
              status: order!.status,
              onAddItems: showAddItems
                  ? () => startAddToOrderFlow(context, ref, order: order)
                  : null,
              onPrint: showPrint ? () => _printKitchen(order) : null,
              printing: _printing,
              onAdvance: showAdvance ? () => _advanceStatus(order) : null,
              advancing: _updatingStatus,
              onRemove: showRemove ? () => _removeOrder(order) : null,
              removing: _cancelling,
              removeLabel: OrderStatusDisplay.removeButtonLabel(order.status),
              isDelete: OrderStatusDisplay.canDelete(order.status),
            )
          : null,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? LoadErrorPanel(message: _error!, onRetry: _load)
          : order == null
          ? const Center(child: Text('订单不存在'))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  _OrderSummaryCard(order: order),
                  const SizedBox(height: 12),
                  Text(
                    '菜品明细 · ${order.items.fold<int>(0, (sum, e) => sum + e.quantity)}件',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  if (order.items.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: Text('暂无菜品明细')),
                      ),
                    )
                  else
                    ...order.items.asMap().entries.map(
                      (entry) => _OrderItemCard(
                        item: entry.value,
                        onRemove: canEditItems
                            ? () => _removeItemAt(order, entry.key)
                            : null,
                        removing: _removingItemIndex == entry.key,
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}

class _OrderSummaryCard extends StatelessWidget {
  const _OrderSummaryCard({required this.order});

  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    final actualAmount = order.actualAmount;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: OrderTableHeadline(order: order)),
                const SizedBox(width: 12),
                Text(
                  Money.formatYuan(order.totalAmount),
                  style: const TextStyle(
                    color: AppColors.error,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                OrderStatusChip(status: order.status),
                if (order.createdAtLabel != null)
                  Text(
                    '下单 ${order.createdAtLabel}',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _AmountBlock(
                    label: '应收',
                    amount: order.totalAmount,
                    emphasized: true,
                  ),
                ),
                if (actualAmount != null) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: _AmountBlock(label: '实收', amount: actualAmount),
                  ),
                ],
              ],
            ),
            if (order.remark != null && order.remark!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('备注：${order.remark}'),
            ],
          ],
        ),
      ),
    );
  }
}

class _AmountBlock extends StatelessWidget {
  const _AmountBlock({
    required this.label,
    required this.amount,
    this.emphasized = false,
  });

  final String label;
  final double amount;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: emphasized
            ? AppColors.error.withValues(alpha: 0.08)
            : AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            Money.formatYuan(amount),
            style: TextStyle(
              color: emphasized ? AppColors.error : AppColors.primary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderItemCard extends StatelessWidget {
  const _OrderItemCard({
    required this.item,
    this.onRemove,
    this.removing = false,
  });

  final OrderLineItem item;
  final VoidCallback? onRemove;
  final bool removing;

  @override
  Widget build(BuildContext context) {
    final lineAmount = item.amount > 0
        ? item.amount
        : item.unitPrice * item.quantity;
    final hasSpec = item.specInfo != null && item.specInfo!.isNotEmpty;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.menuName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  if (hasSpec) ...[
                    const SizedBox(height: 4),
                    Text(
                      item.specInfo!,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    '${item.quantity} × ${Money.formatYuan(item.unitPrice)}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  Money.formatYuan(lineAmount),
                  style: const TextStyle(
                    color: AppColors.error,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                if (onRemove != null) ...[
                  const SizedBox(height: 4),
                  IconButton(
                    onPressed: removing ? null : onRemove,
                    icon: removing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.delete_outline_rounded, size: 20),
                    color: AppColors.error,
                    visualDensity: VisualDensity.compact,
                    tooltip: '删除',
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
