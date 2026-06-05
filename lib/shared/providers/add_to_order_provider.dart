import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/models.dart';

/// 为已有订单加菜时的会话（购物车只放新增项，提交时与原单合并）
class AddToOrderSession {
  const AddToOrderSession({
    required this.order,
    required this.menuNameToId,
  });

  final OrderModel order;
  final Map<String, String> menuNameToId;

  int get existingItemCount =>
      order.items.fold<int>(0, (sum, e) => sum + e.quantity);

  String get headline {
    final loc = order.locationLabel;
    final no = order.orderNo.isNotEmpty ? order.orderNo : '#${order.id}';
    return '$loc · $no';
  }
}

class AddToOrderNotifier extends StateNotifier<AddToOrderSession?> {
  AddToOrderNotifier() : super(null);

  void start(OrderModel order, Map<String, String> menuNameToId) {
    state = AddToOrderSession(order: order, menuNameToId: menuNameToId);
  }

  void clear() => state = null;
}

final addToOrderProvider =
    StateNotifierProvider<AddToOrderNotifier, AddToOrderSession?>((ref) {
      return AddToOrderNotifier();
    });
