import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/load_error_panel.dart';
import '../../core/utils/money.dart';
import '../../data/models/models.dart';
import '../../shared/providers/app_providers.dart';
import '../../shared/widgets/order_status_chip.dart';

class OrderDetailPage extends ConsumerStatefulWidget {
  const OrderDetailPage({super.key, required this.orderId});

  final String orderId;

  @override
  ConsumerState<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends ConsumerState<OrderDetailPage> {
  OrderModel? _order;
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
      final order =
          await ref.read(orderRepositoryProvider).getOrder(widget.orderId);
      if (mounted) setState(() => _order = order);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('订单详情')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? LoadErrorPanel(message: _error!, onRetry: _load)
              : _order == null
                  ? const Center(child: Text('订单不存在'))
                  : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _order!.orderNo.isNotEmpty
                                        ? _order!.orderNo
                                        : '#${_order!.id}',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                OrderStatusChip(status: _order!.status),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${_order!.orderType == 'dine_in' ? '堂食' : '外带'}'
                              '${_order!.tableCode != null ? ' · 桌 ${_order!.tableCode}' : ''}',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            if (_order!.createdAtLabel != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                '下单时间 ${_order!.createdAtLabel}',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                            const SizedBox(height: 4),
                            Text(
                              '合计 ${Money.formatYuan(_order!.totalAmount)}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFFF4D4F),
                              ),
                            ),
                            if (_order!.remark != null &&
                                _order!.remark!.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text('备注：${_order!.remark}'),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '菜品明细',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    ..._order!.items.map(
                      (item) => Card(
                        child: ListTile(
                          title: Text(item.menuName),
                          subtitle: item.specInfo != null
                              ? Text(item.specInfo!)
                              : null,
                          trailing: Text(
                            '${item.quantity} × ${Money.formatYuan(item.unitPrice)}',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}
