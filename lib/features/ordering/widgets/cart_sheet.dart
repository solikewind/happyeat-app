import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/money.dart';
import '../../../shared/providers/app_providers.dart';

class CartSheet extends ConsumerStatefulWidget {
  const CartSheet({super.key});

  @override
  ConsumerState<CartSheet> createState() => _CartSheetState();
}

class _CartSheetState extends ConsumerState<CartSheet> {
  final _remarkCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _remarkCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final cart = ref.read(cartProvider);
    if (cart.isEmpty) return;

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
      final total = ref.read(cartProvider.notifier).totalYuan;
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
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('下单成功，可在订单页查看')));
        context.go('/orders');
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

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final total = cart.fold<double>(0, (sum, item) => sum + item.lineTotal);
    final orderType = ref.watch(orderTypeProvider);
    final table = ref.watch(currentTableProvider);

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
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    const Text('购物车', style: AppStyles.pageTitle),
                    const Spacer(),
                    TextButton(
                      onPressed: cart.isEmpty
                          ? null
                          : () => ref.read(cartProvider.notifier).clear(),
                      child: const Text('清空'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: cart.isEmpty
                    ? const Center(child: Text('购物车是空的'))
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: cart.length,
                        itemBuilder: (context, index) {
                          final item = cart[index];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(item.name),
                            subtitle: item.specInfo != null
                                ? Text(item.specInfo!)
                                : null,
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove),
                                  onPressed: () => ref
                                      .read(cartProvider.notifier)
                                      .updateQty(
                                        item.cartKey,
                                        item.quantity - 1,
                                      ),
                                ),
                                Text('${item.quantity}'),
                                IconButton(
                                  icon: const Icon(Icons.add),
                                  onPressed: () => ref
                                      .read(cartProvider.notifier)
                                      .updateQty(
                                        item.cartKey,
                                        item.quantity + 1,
                                      ),
                                ),
                                SizedBox(
                                  width: 64,
                                  child: Text(
                                    Money.formatYuan(item.lineTotal),
                                    textAlign: TextAlign.end,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      orderType == 'dine_in'
                          ? '堂食 · ${table?.code ?? '未选桌'}'
                          : '打包外带',
                      style: const TextStyle(color: Color(0xFF667085)),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _remarkCtrl,
                      decoration: const InputDecoration(
                        labelText: '备注',
                        hintText: '少辣、不要葱…',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text(
                          '合计 ${Money.formatYuan(total)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        FilledButton(
                          onPressed: cart.isEmpty || _submitting
                              ? null
                              : _submit,
                          child: _submitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('确认下单'),
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
