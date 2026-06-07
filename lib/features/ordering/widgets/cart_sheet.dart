import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/money.dart';
import '../../../data/models/models.dart';
import '../../../shared/providers/add_to_order_provider.dart';
import '../../../shared/providers/app_providers.dart';

class CartSheet extends ConsumerStatefulWidget {
  const CartSheet({super.key, this.onPlacedNewOrder});

  /// 堂食新单下单成功（由点餐页传入，确保桌台 UI 同步清空）
  final VoidCallback? onPlacedNewOrder;

  @override
  ConsumerState<CartSheet> createState() => _CartSheetState();
}

class _CartSheetState extends ConsumerState<CartSheet> {
  final _remarkCtrl = TextEditingController();
  bool _submitting = false;

  /// 与 Web 点餐台一致，避免浮点误差
  static double _roundYuan(double yuan) => (yuan * 100).round() / 100;

  @override
  void dispose() {
    _remarkCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final cart = ref.read(cartProvider);
    if (cart.isEmpty) return;

    final addSession = ref.read(addToOrderProvider);
    if (addSession != null) {
      await _submitAddToOrder(addSession, cart);
      return;
    }

    final orderType = ref.read(orderTypeProvider);
    final table = ref.read(currentTableProvider);
    if (orderType == 'dine_in' && table == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('堂食请先选择桌号')));
      return;
    }

    setState(() => _submitting = true);
    try {
      final total = _roundYuan(ref.read(cartProvider.notifier).totalYuan);
      await ref
          .read(orderRepositoryProvider)
          .createOrder(
            orderType: orderType,
            tableId: table?.id,
            items: cart,
            totalYuan: total,
            remark: _remarkCtrl.text.trim(),
          );
      ref.read(cartProvider.notifier).clear();
      if (orderType == 'dine_in') {
        clearSelectedTable(ref);
        widget.onPlacedNewOrder?.call();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          clearSelectedTable(ref);
          widget.onPlacedNewOrder?.call();
        });
      }
      _remarkCtrl.clear();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('下单成功，可在订单页查看')));
        final shell = StatefulNavigationShell.maybeOf(context);
        if (shell != null) {
          shell.goBranch(ShellTab.orders);
        } else {
          context.go('/orders');
        }
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _submitAddToOrder(
    AddToOrderSession session,
    List<CartItem> cart,
  ) async {
    setState(() => _submitting = true);
    try {
      final fresh = await ref
          .read(orderRepositoryProvider)
          .getOrder(session.order.id);
      await ref.read(orderRepositoryProvider).updateOrderItems(
        orderId: fresh.id,
        existingItems: fresh.items,
        newItems: cart,
        menuNameToId: session.menuNameToId,
      );
      ref.read(cartProvider.notifier).clear();
      ref.read(addToOrderProvider.notifier).clear();
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('加菜成功，厨房将打印加菜单')));
      context.push('/orders/${fresh.id}');
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final total = cart.fold<double>(0, (sum, item) => sum + item.lineTotal);
    final addSession = ref.watch(addToOrderProvider);
    final orderType = ref.watch(orderTypeProvider);
    final table = ref.watch(currentTableProvider);
    final isAddMode = addSession != null;
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: AppStyles.sheetTop(),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
                child: Row(
                  children: [
                    Text(
                      isAddMode ? '本次加菜' : '购物车',
                      style: AppStyles.pageTitle,
                    ),
                    if (cart.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${cart.fold<int>(0, (s, e) => s + e.quantity)} 件',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                    const Spacer(),
                    TextButton.icon(
                      onPressed: cart.isEmpty
                          ? null
                          : () => ref.read(cartProvider.notifier).clear(),
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: const Text('清空'),
                    ),
                  ],
                ),
              ),
              if (isAddMode)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '原单已有 ${addSession.existingItemCount} 件，此处仅显示新增',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF667085),
                      ),
                    ),
                  ),
                ),
              Expanded(
                child: cart.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.shopping_cart_outlined,
                              size: 56,
                              color: Colors.grey.shade300,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '购物车是空的',
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '去菜单挑选喜欢的菜品吧',
                              style: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                        itemCount: cart.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final item = cart[index];
                          return _CartItemTile(
                            item: item,
                            onDecrease: () => ref
                                .read(cartProvider.notifier)
                                .updateQty(item.cartKey, item.quantity - 1),
                            onIncrease: () => ref
                                .read(cartProvider.notifier)
                                .updateQty(item.cartKey, item.quantity + 1),
                          );
                        },
                      ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: AppStyles.border)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                padding: EdgeInsets.fromLTRB(16, 14, 16, 16 + bottomPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isAddMode
                              ? Icons.receipt_long_outlined
                              : orderType == 'dine_in'
                              ? Icons.table_restaurant_outlined
                              : Icons.takeout_dining_outlined,
                          size: 18,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            isAddMode
                                ? addSession.headline
                                : orderType == 'dine_in'
                                ? '堂食 · ${table?.code ?? '未选桌'}'
                                : '打包外带',
                            style: const TextStyle(
                              color: Color(0xFF667085),
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (!isAddMode) ...[
                      const SizedBox(height: 10),
                      TextField(
                        controller: _remarkCtrl,
                        decoration: InputDecoration(
                          labelText: '备注',
                          hintText: '少辣、不要葱…',
                          filled: true,
                          fillColor: AppStyles.surfaceMuted,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppStyles.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppStyles.border),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isAddMode ? '新增合计' : '合计',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Text(
                              Money.formatYuan(total),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: AppStyles.price,
                                height: 1.1,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        FilledButton(
                          onPressed: cart.isEmpty || _submitting ? null : _submit,
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(120, 48),
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                          ),
                          child: _submitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(isAddMode ? '确认加菜' : '确认下单'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CartItemTile extends StatelessWidget {
  const _CartItemTile({
    required this.item,
    required this.onDecrease,
    required this.onIncrease,
  });

  final CartItem item;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: AppStyles.surfaceCard(radius: AppStyles.radiusMd),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: AppStyles.textPrimary,
                  ),
                ),
                if (item.specInfo != null && item.specInfo!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.specInfo!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Text(
                  '${Money.formatYuan(item.unitPrice)} / 份',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                Money.formatYuan(item.lineTotal),
                style: const TextStyle(
                  color: AppStyles.price,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: AppStyles.surfaceMuted,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppStyles.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _QtyButton(icon: Icons.remove, onTap: onDecrease),
                    Container(
                      constraints: const BoxConstraints(minWidth: 32),
                      alignment: Alignment.center,
                      child: Text(
                        '${item.quantity}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    _QtyButton(icon: Icons.add, onTap: onIncrease),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  const _QtyButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(icon, size: 18, color: AppColors.primary),
        ),
      ),
    );
  }
}
