import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_styles.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/models.dart';
import '../../shared/providers/app_providers.dart';
import '../../shared/widgets/cart_bottom_bar.dart';
import '../../shared/widgets/load_error_panel.dart';
import 'widgets/cart_sheet.dart';
import 'widgets/category_rail.dart';
import 'widgets/menu_list_tile.dart';
import 'widgets/order_mode_bar.dart';
import 'widgets/ordering_header.dart';
import 'widgets/spec_picker_sheet.dart';
import 'widgets/table_picker_sheet.dart';

class OrderingPage extends ConsumerStatefulWidget {
  const OrderingPage({super.key});

  @override
  ConsumerState<OrderingPage> createState() => _OrderingPageState();
}

class _OrderingPageState extends ConsumerState<OrderingPage> {
  List<MenuCategory> _categories = [];
  List<MenuItem> _allMenus = [];
  String _activeCategory = 'all';
  String _search = '';
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _refreshAll();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybePromptTable());
  }

  void _openTablePicker() {
    showTablePickerSheet(context, ref).then((picked) {
      if (!mounted || picked == null) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('已选桌 ${picked.code}'),
          duration: const Duration(seconds: 1),
        ),
      );
    });
  }

  void _maybePromptTable() {
    if (!mounted) return;
    if (ref.read(orderTypeProvider) == 'dine_in' &&
        ref.read(currentTableProvider) == null) {
      _openTablePicker();
    }
  }

  Future<void> _refreshAll() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = ref.read(menuRepositoryProvider);
      final results = await Future.wait([
        repo.listCategories(),
        repo.listMenus(),
      ]);
      if (!mounted) return;
      setState(() {
        _categories = results[0] as List<MenuCategory>;
        _allMenus = results[1] as List<MenuItem>;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Map<String, String> get _categoryNameById {
    return {for (final c in _categories) c.id: c.name};
  }

  List<MenuItem> get _categoryMenus {
    if (_activeCategory == 'all') return _allMenus;
    return _allMenus.where((m) {
      final name = _categoryNameById[m.categoryId];
      return name == _activeCategory;
    }).toList();
  }

  List<MenuItem> get _filteredMenus {
    final q = _search.trim().toLowerCase();
    if (q.isEmpty) return _categoryMenus;
    return _categoryMenus.where((m) => m.name.toLowerCase().contains(q)).toList();
  }

  bool _ensureDineInTable() {
    if (ref.read(orderTypeProvider) != 'dine_in') return true;
    if (ref.read(currentTableProvider) != null) return true;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('堂食请先选择餐桌')),
    );
    _openTablePicker();
    return false;
  }

  void _openSpecPicker(MenuItem menu) {
    if (!_ensureDineInTable()) return;
    if (menu.specs.isEmpty) {
      _addToCart(menu, 1, []);
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SpecPickerSheet(
        menu: menu,
        onConfirm: (qty, specs) => _addToCart(menu, qty, specs),
      ),
    );
  }

  void _addToCart(MenuItem menu, int qty, List<MenuSpec> specs) {
    final delta = specs.fold<double>(0, (s, e) => s + e.priceDelta);
    final unit = menu.priceYuan + delta;
    final specInfo = specs.isEmpty
        ? null
        : specs.map((s) => '${s.specType}:${s.specValue}').join(' ');

    ref.read(cartProvider.notifier).add(
          CartItem(
            menuId: menu.id,
            name: menu.name,
            unitPrice: unit,
            quantity: qty,
            specInfo: specInfo,
            image: menu.image,
          ),
        );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已添加 ${menu.name} ×$qty'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _openCartSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CartSheet(),
    );
  }

  Widget _buildMenuPanel() {
    if (_loading && _allMenus.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _allMenus.isEmpty) {
      return LoadErrorPanel(message: _error!, onRetry: _refreshAll);
    }
    if (_filteredMenus.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 80),
          Icon(Icons.restaurant_outlined, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          const Center(
            child: Text(
              '暂无菜品',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ],
      );
    }
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      itemCount: _filteredMenus.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final menu = _filteredMenus[index];
        return MenuListTile(
          menu: menu,
          onAdd: () => _openSpecPicker(menu),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartCount = ref.watch(cartProvider.notifier).itemCount;
    final cartTotal = ref.watch(cartProvider.notifier).totalYuan;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          OrderingHeader(onSearchChanged: (v) => setState(() => _search = v)),
          OrderModeBar(onPickTable: _openTablePicker),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CategoryRail(
                  categories: _categories.map((c) => c.name).toList(),
                  activeKey: _activeCategory,
                  onSelected: (key) => setState(() => _activeCategory = key),
                ),
                Expanded(
                  child: RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: _refreshAll,
                    child: _buildMenuPanel(),
                  ),
                ),
              ],
            ),
          ),
          CartBottomBar(
            itemCount: cartCount,
            totalYuan: cartTotal,
            onTap: _openCartSheet,
            onCheckout: _openCartSheet,
          ),
        ],
      ),
    );
  }
}
