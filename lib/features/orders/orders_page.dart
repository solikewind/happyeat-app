import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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

class OrdersPage extends ConsumerStatefulWidget {
  const OrdersPage({super.key});

  @override
  ConsumerState<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends ConsumerState<OrdersPage> {
  List<OrderModel> _orders = [];
  String? _statusFilter = 'created';
  bool _loading = true;
  String? _updatingOrderId;
  String? _printingOrderId;
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
      final result = await ref
          .read(orderRepositoryProvider)
          .listOrders(status: _statusFilter, pageSize: 50);
      if (mounted) setState(() => _orders = result.orders);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted && !silent) setState(() => _loading = false);
    }
  }

  Future<void> _advanceStatus(OrderModel order) async {
    final next = OrderStatusDisplay.workbenchAdvanceTarget(order.status);
    if (next == null || _updatingOrderId != null) return;

    setState(() => _updatingOrderId = order.id);
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
      if (mounted) setState(() => _updatingOrderId = null);
    }
  }

  Future<void> _printKitchen(OrderModel order) async {
    if (_printingOrderId != null) return;
    setState(() => _printingOrderId = order.id);
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
      if (mounted) setState(() => _printingOrderId = null);
    }
  }

  bool _canPrintKitchen(OrderModel order) {
    final s = order.status.trim().toLowerCase();
    return s != 'cancelled';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('订单')),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: Row(
              children: [
                _FilterChip(
                  label: '全部',
                  selected: _statusFilter == null,
                  onTap: () {
                    setState(() => _statusFilter = null);
                    _load();
                  },
                ),
                _FilterChip(
                  label: '待支付',
                  selected: _statusFilter == 'created',
                  onTap: () {
                    setState(() => _statusFilter = 'created');
                    _load();
                  },
                ),
                _FilterChip(
                  label: '已支付',
                  selected: _statusFilter == 'paid',
                  onTap: () {
                    setState(() => _statusFilter = 'paid');
                    _load();
                  },
                ),
                _FilterChip(
                  label: '制作中',
                  selected: _statusFilter == 'preparing',
                  onTap: () {
                    setState(() => _statusFilter = 'preparing');
                    _load();
                  },
                ),
                _FilterChip(
                  label: '已完成',
                  selected: _statusFilter == 'completed',
                  onTap: () {
                    setState(() => _statusFilter = 'completed');
                    _load();
                  },
                ),
                _FilterChip(
                  label: '已取消',
                  selected: _statusFilter == 'cancelled',
                  onTap: () {
                    setState(() => _statusFilter = 'cancelled');
                    _load();
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.45,
                          child: LoadErrorPanel(
                            message: _error!,
                            onRetry: _load,
                          ),
                        ),
                      ],
                    )
                  : _orders.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(
                          height: 200,
                          child: Center(child: Text('暂无订单')),
                        ),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: _orders.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final order = _orders[index];
                        return _OrderCard(
                          order: order,
                          advancing: _updatingOrderId == order.id,
                          printing: _printingOrderId == order.id,
                          onPrint: _canPrintKitchen(order)
                              ? () => _printKitchen(order)
                              : null,
                          onAdvance:
                              OrderStatusDisplay.workbenchAdvanceTarget(
                                    order.status,
                                  ) !=
                                  null
                              ? () => _advanceStatus(order)
                              : null,
                          onTap: () => context.push('/orders/${order.id}'),
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

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: AppColors.primary.withValues(alpha: 0.15),
        checkmarkColor: AppColors.primary,
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.order,
    required this.onTap,
    this.onAdvance,
    this.onPrint,
    this.advancing = false,
    this.printing = false,
  });

  final OrderModel order;
  final VoidCallback onTap;
  final VoidCallback? onAdvance;
  final VoidCallback? onPrint;
  final bool advancing;
  final bool printing;

  @override
  Widget build(BuildContext context) {
    final itemCount = order.items.fold<int>(0, (sum, e) => sum + e.quantity);
    final summaryItems = order.items
        .take(2)
        .map((e) => '${e.menuName}×${e.quantity}')
        .join('、');
    final summary = order.items.length > 2
        ? '$summaryItems 等$itemCount件'
        : summaryItems;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: OrderTableHeadline(order: order, compact: true),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        Money.formatYuan(order.totalAmount),
                        style: const TextStyle(
                          color: AppColors.error,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      OrderStatusChip(status: order.status),
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
                  if (summary.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      summary,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (onPrint != null || onAdvance != null) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (onPrint != null)
                    OutlinedButton.icon(
                      onPressed: printing ? null : onPrint,
                      icon: printing
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.print_outlined, size: 16),
                      label: const Text('打印'),
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                      ),
                    ),
                  if (onPrint != null && onAdvance != null)
                    const SizedBox(width: 8),
                  if (onAdvance != null)
                    OrderAdvanceButton(
                      status: order.status,
                      compact: true,
                      loading: advancing,
                      onPressed: onAdvance,
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
