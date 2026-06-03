import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/money.dart';
import '../../data/models/models.dart';
import '../../shared/providers/app_providers.dart';
import '../../shared/widgets/load_error_panel.dart';
import '../../shared/widgets/order_status_chip.dart';

class OrdersPage extends ConsumerStatefulWidget {
  const OrdersPage({super.key});

  @override
  ConsumerState<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends ConsumerState<OrdersPage> {
  List<OrderModel> _orders = [];
  String? _statusFilter;
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
      final result = await ref.read(orderRepositoryProvider).listOrders(
            status: _statusFilter,
            pageSize: 50,
          );
      if (mounted) setState(() => _orders = result.orders);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final order = _orders[index];
                                return _OrderCard(
                                  order: order,
                                  onTap: () =>
                                      context.push('/orders/${order.id}'),
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
  const _OrderCard({required this.order, required this.onTap});

  final OrderModel order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final summary = order.items
        .take(3)
        .map((e) => '${e.menuName}×${e.quantity}')
        .join('、');

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      order.orderNo.isNotEmpty
                          ? order.orderNo
                          : '#${order.id}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  OrderStatusChip(status: order.status),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                [
                  order.orderType == 'dine_in' ? '堂食' : '外带',
                  if (order.tableCode != null) '桌 ${order.tableCode}',
                  Money.formatYuan(order.totalAmount),
                  if (order.createdAtLabel != null) order.createdAtLabel!,
                ].join(' · '),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              if (summary.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  summary,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
