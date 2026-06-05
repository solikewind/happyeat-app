import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/models.dart';

export 'add_to_order_provider.dart';
export 'api_providers.dart';
export 'auth_provider.dart';
export 'settings_provider.dart';

import '../utils/table_display.dart';
import 'api_providers.dart';

/// 底栏 Tab 索引，用于切换 Tab 时触发页面刷新
abstract final class ShellTab {
  static const ordering = 0;
  static const orders = 1;
  static const tables = 2;
  static const profile = 3;
}

final shellTabIndexProvider = StateProvider<int>((ref) => ShellTab.ordering);

/// 堂食 dine_in / 外带 takeaway
final orderTypeProvider = StateProvider<String>((ref) => 'dine_in');

final currentTableProvider = StateProvider<TableItem?>((ref) => null);

/// 餐桌分类 id → 名称（选桌、点餐栏展示用）
final tableCategoryMapProvider = FutureProvider<Map<String, String>>((
  ref,
) async {
  final cats = await ref.read(tableRepositoryProvider).listTableCategories();
  return TableDisplay.categoryNameById(cats);
});

final cartProvider = StateNotifierProvider<CartNotifier, List<CartItem>>((ref) {
  return CartNotifier();
});

class CartNotifier extends StateNotifier<List<CartItem>> {
  CartNotifier() : super(const []);

  void add(CartItem item) {
    final idx = state.indexWhere((e) => e.cartKey == item.cartKey);
    if (idx >= 0) {
      final updated = [...state];
      updated[idx] = updated[idx].copyWith(
        quantity: updated[idx].quantity + item.quantity,
      );
      state = updated;
    } else {
      state = [...state, item];
    }
  }

  void updateQty(String cartKey, int qty) {
    if (qty <= 0) {
      remove(cartKey);
      return;
    }
    state = [
      for (final item in state)
        if (item.cartKey == cartKey) item.copyWith(quantity: qty) else item,
    ];
  }

  void remove(String cartKey) {
    state = state.where((e) => e.cartKey != cartKey).toList();
  }

  void clear() => state = [];

  int get itemCount => state.fold(0, (sum, e) => sum + e.quantity);

  double get totalYuan => state.fold(0, (sum, e) => sum + e.lineTotal);
}
