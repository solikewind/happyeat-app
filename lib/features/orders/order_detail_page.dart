import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/money.dart';
import '../../data/models/models.dart';
import '../../shared/providers/app_providers.dart';
import '../../shared/utils/order_status_display.dart';
import '../../shared/widgets/load_error_panel.dart';
import '../../shared/widgets/order_advance_button.dart';
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(OrderStatusDisplay.advanceSuccessMessage(next))),
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
      ).showSnackBar(const SnackBar(content: Text('已提交厨房打印')));
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

  @override
  Widget build(BuildContext context) {
    final order = _order;
    final showAdvance =
        order != null &&
        OrderStatusDisplay.workbenchAdvanceTarget(order.status) != null;
    final showPrint = order != null && _canPrintKitchen(order);
    final showBottomBar = showAdvance || showPrint;
    return Scaffold(
      appBar: AppBar(title: const Text('订单详情')),
      bottomNavigationBar: showBottomBar
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (showPrint)
                      OutlinedButton.icon(
                        onPressed: _printing
                            ? null
                            : () => _printKitchen(order!),
                        icon: _printing
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.print_outlined),
                        label: const Text('厨房打印'),
                      ),
                    if (showPrint && showAdvance) const SizedBox(height: 8),
                    if (showAdvance)
                      OrderAdvanceButton(
                        status: order!.status,
                        loading: _updatingStatus,
                        onPressed: () => _advanceStatus(order),
                      ),
                  ],
                ),
              ),
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
                    ...order.items.map((item) => _OrderItemCard(item: item)),
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
  const _OrderItemCard({required this.item});

  final OrderLineItem item;

  @override
  Widget build(BuildContext context) {
    final lineAmount = item.amount > 0
        ? item.amount
        : item.unitPrice * item.quantity;
    return Card(
      child: ListTile(
        title: Text(item.menuName),
        subtitle: Text(
          [
            if (item.specInfo != null && item.specInfo!.isNotEmpty)
              item.specInfo!,
            '${item.quantity} × ${Money.formatYuan(item.unitPrice)}',
          ].join('\n'),
        ),
        isThreeLine: item.specInfo != null && item.specInfo!.isNotEmpty,
        trailing: Text(
          Money.formatYuan(lineAmount),
          style: const TextStyle(
            color: AppColors.error,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
