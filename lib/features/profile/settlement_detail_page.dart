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
import '../../shared/widgets/order_status_chip.dart';
import '../../shared/widgets/order_table_headline.dart';
import 'add_settlement_orders_sheet.dart';

class SettlementDetailPage extends ConsumerStatefulWidget {
  const SettlementDetailPage({super.key, required this.settlementId});

  final String settlementId;

  @override
  ConsumerState<SettlementDetailPage> createState() =>
      _SettlementDetailPageState();
}

class _SettlementDetailPageState extends ConsumerState<SettlementDetailPage> {
  SettlementModel? _settlement;
  bool _loading = true;
  String? _error;
  bool _submitting = false;
  String? _removingOrderId;

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
      final settlement = await ref
          .read(settlementRepositoryProvider)
          .getSettlement(widget.settlementId);
      if (mounted) setState(() => _settlement = settlement);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted && !silent) setState(() => _loading = false);
    }
  }

  Future<void> _addOrders() async {
    final settlement = _settlement;
    if (settlement == null || !settlement.isUnsettled) return;
    final updated = await showModalBottomSheet<SettlementModel>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => SizedBox(
        height: MediaQuery.of(ctx).size.height * 0.75,
        child: AddSettlementOrdersSheet(
          settlementId: settlement.id,
          onAdded: (next) {
            if (mounted) setState(() => _settlement = next);
          },
        ),
      ),
    );
    if (updated != null && mounted) {
      setState(() => _settlement = updated);
    }
  }

  Future<bool> _removeOrder(OrderModel order) async {
    final settlement = _settlement;
    if (settlement == null || _removingOrderId != null) return false;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('移出订单'),
        content: Text('确定从结账单中移出订单 ${order.orderNo}？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('移出'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return false;

    setState(() => _removingOrderId = order.id);
    try {
      final updated = await ref.read(settlementRepositoryProvider).removeOrder(
        settlementId: settlement.id,
        orderId: order.id,
      );
      if (!mounted) return false;
      showBriefSnackBar(context, '已移出订单');
      setState(() => _settlement = updated);
      return true;
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
      return false;
    } finally {
      if (mounted) setState(() => _removingOrderId = null);
    }
  }

  Future<void> _settle() async {
    final settlement = _settlement;
    if (settlement == null || !settlement.isUnsettled || _submitting) return;
    if (settlement.orders.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先添加订单再结账')),
      );
      return;
    }

    final amountCtrl = TextEditingController(
      text: settlement.totalAmount.toStringAsFixed(2),
    );
    final remarkCtrl = TextEditingController(text: settlement.remark ?? '');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('结账单结账'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '应收 ${Money.formatYuan(settlement.totalAmount)}',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: '实收金额'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: remarkCtrl,
              decoration: const InputDecoration(labelText: '备注（可选）'),
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
            child: const Text('确认结账'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final actual = double.tryParse(amountCtrl.text.trim());
    if (actual == null || actual < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入有效实收金额')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final updated = await ref.read(settlementRepositoryProvider).settle(
        settlementId: settlement.id,
        actualYuan: actual,
        remark: remarkCtrl.text.trim(),
      );
      if (!mounted) return;
      showBriefSnackBar(context, '结账成功');
      setState(() => _settlement = updated);
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

  Future<void> _deleteSettlement() async {
    final settlement = _settlement;
    if (settlement == null || !settlement.isUnsettled || _submitting) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除结账单'),
        content: Text(
          settlement.orders.isNotEmpty
              ? '将删除此结账单，${settlement.orders.length} 笔关联订单会自动解绑，确定继续？'
              : '确定删除此空结账单？',
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

    setState(() => _submitting = true);
    try {
      await ref.read(settlementRepositoryProvider).deleteSettlement(settlement.id);
      if (!mounted) return;
      showBriefSnackBar(context, '结账单已删除');
      context.pop();
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
    final settlement = _settlement;
    final unsettled = settlement?.isUnsettled ?? false;
    return Scaffold(
      appBar: AppBar(
        title: Text(settlement?.customerName ?? '结账单详情'),
        actions: [
          if (unsettled && settlement != null)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              color: AppColors.error,
              tooltip: '删除结账单',
              onPressed: _submitting ? null : _deleteSettlement,
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _load,
          ),
        ],
      ),
      bottomNavigationBar: unsettled && settlement != null
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _submitting ? null : _addOrders,
                        icon: const Icon(Icons.add),
                        label: const Text('添加订单'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _submitting ? null : _settle,
                        icon: _submitting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.payments_outlined),
                        label: const Text('结账'),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
      body: _loading && settlement == null
          ? const Center(child: CircularProgressIndicator())
          : _error != null && settlement == null
          ? LoadErrorPanel(message: _error!, onRetry: _load)
          : settlement == null
          ? const Center(child: Text('结账单不存在'))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  _SummaryCard(settlement: settlement),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text(
                        '关联订单 · ${settlement.orders.length}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (settlement.orders.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Center(child: Text('暂无订单')),
                      ),
                    )
                  else
                    ...settlement.orders.map(
                      (order) {
                        final card = _SettlementOrderCard(
                          order: order,
                          canRemove: unsettled,
                          removing: _removingOrderId == order.id,
                          onTap: () => context.push('/orders/${order.id}'),
                          onRemove:
                              unsettled ? () => _removeOrder(order) : null,
                        );
                        if (!unsettled) return card;
                        return Dismissible(
                          key: ValueKey('settlement-order-${order.id}'),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.remove_circle_outline,
                              color: AppColors.error,
                            ),
                          ),
                          confirmDismiss: (_) => _removeOrder(order),
                          child: card,
                        );
                      },
                    ),
                ],
              ),
            ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.settlement});

  final SettlementModel settlement;

  @override
  Widget build(BuildContext context) {
    final unsettled = settlement.isUnsettled;
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
                    settlement.customerName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: (unsettled ? AppColors.warning : AppColors.success)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    SettlementDisplay.statusLabel(settlement.status),
                    style: TextStyle(
                      color: unsettled ? AppColors.warning : AppColors.success,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _AmountTile(
                    label: '应收合计',
                    amount: settlement.totalAmount,
                    emphasized: unsettled,
                  ),
                ),
                if (!unsettled) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: _AmountTile(
                      label: '实收合计',
                      amount: settlement.actualAmount,
                    ),
                  ),
                ],
              ],
            ),
            if (settlement.remark != null && settlement.remark!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('备注：${settlement.remark}'),
            ],
            if (settlement.settledAt != null) ...[
              const SizedBox(height: 8),
              Text(
                '结账时间：${SettlementDisplay.formatDateTime(settlement.settledAt) ?? settlement.settledAt}',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AmountTile extends StatelessWidget {
  const _AmountTile({
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
        color: (emphasized ? AppColors.error : AppColors.primary)
            .withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
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

class _SettlementOrderCard extends StatelessWidget {
  const _SettlementOrderCard({
    required this.order,
    required this.onTap,
    this.onRemove,
    this.canRemove = false,
    this.removing = false,
  });

  final OrderModel order;
  final VoidCallback onTap;
  final VoidCallback? onRemove;
  final bool canRemove;
  final bool removing;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    OrderTableHeadline(order: order),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        OrderStatusChip(status: order.status),
                        Text(
                          order.orderNo,
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
              Text(
                Money.formatYuan(order.totalAmount),
                style: const TextStyle(
                  color: AppColors.error,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              if (canRemove && onRemove != null)
                IconButton(
                  onPressed: removing ? null : onRemove,
                  icon: removing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.remove_circle_outline),
                  color: AppColors.error,
                  tooltip: '移出',
                ),
            ],
          ),
        ),
      ),
    );
  }
}
