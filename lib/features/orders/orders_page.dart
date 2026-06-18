import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/money.dart';
import '../../data/models/models.dart';
import '../../shared/providers/app_providers.dart';
import '../../shared/utils/add_to_order_flow.dart';
import '../../shared/utils/keyboard.dart';
import '../../shared/utils/order_advance_flow.dart';
import '../../shared/utils/order_status_display.dart';
import '../../shared/widgets/brief_snack_bar.dart';
import '../../shared/widgets/load_error_panel.dart';
import '../../shared/widgets/order_action_tile.dart';
import '../../shared/widgets/order_cancel_dialog.dart';
import '../../shared/widgets/order_daily_sequence_chip.dart';
import '../../shared/widgets/order_status_chip.dart';
import '../../shared/widgets/order_swipe_actions.dart';
import '../../shared/widgets/order_swipe_group.dart';
import '../../shared/widgets/order_swipe_scope.dart';
import '../../shared/widgets/order_table_headline.dart';
import '../../shared/widgets/shell_tab_listener.dart';

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
  String? _cancellingOrderId;
  String? _error;
  final _swipeGroup = OrderSwipeGroup();

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
    if (_updatingOrderId != null) return;
    dismissKeyboard();

    setState(() => _updatingOrderId = order.id);
    try {
      final ok = await advanceOrderWithConfirm(
        context: context,
        ref: ref,
        order: order,
      );
      if (ok && mounted) await _load(silent: true);
    } finally {
      if (mounted) setState(() => _updatingOrderId = null);
    }
  }

  Future<void> _printKitchen(OrderModel order) async {
    if (_printingOrderId != null) return;
    dismissKeyboard();
    setState(() => _printingOrderId = order.id);
    try {
      await ref.read(orderRepositoryProvider).printOrderKitchen(order.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('已提交厨房打印'),
          duration: Duration(milliseconds: 1200),
        ),
      );
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

  Future<void> _removeOrder(OrderModel order) async {
    if (_cancellingOrderId != null) return;
    if (!OrderStatusDisplay.canRemove(order.status)) return;
    dismissKeyboard();
    final isDelete = OrderStatusDisplay.canDelete(order.status);
    if (!await confirmRemoveOrder(context, isDelete: isDelete)) return;

    setState(() => _cancellingOrderId = order.id);
    try {
      await ref.read(orderRepositoryProvider).cancelOrder(order.id);
      if (!mounted) return;
      showBriefSnackBar(
        context,
        isDelete
            ? OrderStatusDisplay.deleteSuccessMessage
            : OrderStatusDisplay.cancelSuccessMessage,
      );
      _removeOrderLocally(order);
      await _load(silent: true);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _cancellingOrderId = null);
    }
  }

  /// 取消/删除成功后先本地更新列表，避免等待接口返回前列表无变化。
  void _removeOrderLocally(OrderModel order) {
    final filter = _statusFilter?.trim().toLowerCase();
    setState(() {
      if (filter == null || filter.isEmpty) {
        _orders = [
          for (final o in _orders)
            if (o.id == order.id)
              OrderModel(
                id: o.id,
                orderNo: o.orderNo,
                orderType: o.orderType,
                status: 'cancelled',
                tableId: o.tableId,
                tableCode: o.tableCode,
                tableCategory: o.tableCategory,
                totalAmount: o.totalAmount,
                actualAmount: o.actualAmount,
                remark: o.remark,
                items: o.items,
                createdAt: o.createdAt,
                dailySequence: o.dailySequence,
                settlementId: o.settlementId,
              )
            else
              o,
        ];
      } else {
        _orders = _orders.where((o) => o.id != order.id).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ShellTabListener(
      tabIndex: ShellTab.orders,
      onReselect: () => _load(silent: true),
      child: Scaffold(
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
                    label: '已完成',
                    selected: _statusFilter == 'completed',
                    onTap: () {
                      setState(() => _statusFilter = 'completed');
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
                    : OrderSwipeScope(
                        group: _swipeGroup,
                        child: NotificationListener<ScrollNotification>(
                          onNotification: (notification) {
                            if (notification is ScrollStartNotification) {
                              _swipeGroup.closeCurrent();
                            }
                            return false;
                          },
                          child: ListView.separated(
                            padding: const EdgeInsets.all(12),
                            itemCount: _orders.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final order = _orders[index];
                              return _OrderCard(
                                order: order,
                                advancing: _updatingOrderId == order.id,
                                printing: _printingOrderId == order.id,
                                cancelling: _cancellingOrderId == order.id,
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
                                onAddItems:
                                    OrderStatusDisplay.canAddItems(order.status)
                                    ? () => startAddToOrderFlow(
                                        context,
                                        ref,
                                        order: order,
                                      )
                                    : null,
                                onRemove:
                                    OrderStatusDisplay.canRemove(order.status)
                                    ? () => _removeOrder(order)
                                    : null,
                                onTap: () async {
                                  dismissKeyboard();
                                  await context.push('/orders/${order.id}');
                                  dismissKeyboard();
                                  if (mounted) await _load(silent: true);
                                },
                              );
                            },
                          ),
                        ),
                      ),
              ),
            ),
          ],
        ),
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
    this.onAddItems,
    this.onAdvance,
    this.onPrint,
    this.onRemove,
    this.advancing = false,
    this.printing = false,
    this.cancelling = false,
  });

  final OrderModel order;
  final VoidCallback onTap;
  final VoidCallback? onAddItems;
  final VoidCallback? onAdvance;
  final Future<void> Function()? onPrint;
  final Future<void> Function()? onRemove;
  final bool advancing;
  final bool printing;
  final bool cancelling;

  @override
  Widget build(BuildContext context) {
    final summary = order.items
        .map((e) => '${e.menuName}×${e.quantity}')
        .join('、');
    final isActive = OrderStatusDisplay.isActive(order.status);
    final showSwipeActions = isActive && (onPrint != null || onRemove != null);

    final card = Card(
      margin: EdgeInsets.zero,
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
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                OrderStatusChip(status: order.status),
                                if (order.dailySequence != null &&
                                    order.dailySequence! > 0)
                                  OrderDailySequenceChip(
                                    sequence: order.dailySequence!,
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
                            if (summary.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                summary,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (onPrint != null ||
                onAdvance != null ||
                onRemove != null ||
                onAddItems != null) ...[
              const SizedBox(height: 10),
              OrderListActionBar(
                status: order.status,
                onAdvance: onAdvance,
                advancing: advancing,
                onAddItems: onAddItems,
                onPrint: onPrint,
                printing: printing,
                onRemove: onRemove,
                removing: cancelling,
                removeLabel: OrderStatusDisplay.removeButtonLabel(order.status),
                isDelete: OrderStatusDisplay.canDelete(order.status),
                hidePrintAndRemove: isActive,
              ),
            ],
          ],
        ),
      ),
    );

    if (!showSwipeActions) return card;

    return OrderSwipeActions(
      onPrint: onPrint,
      printing: printing,
      onRemove: onRemove,
      removing: cancelling,
      removeLabel: OrderStatusDisplay.removeButtonLabel(order.status),
      child: card,
    );
  }
}
