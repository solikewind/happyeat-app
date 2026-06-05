import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/models.dart';
import '../../shared/providers/app_providers.dart';
import '../../shared/utils/table_display.dart';
import '../../shared/widgets/cart_bottom_bar.dart';
import '../../shared/widgets/load_error_panel.dart';
import '../../shared/widgets/menu_cover_image.dart';
import '../../shared/widgets/shell_tab_listener.dart';
import 'widgets/add_to_order_banner.dart';
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
  static const double _snackBarBottomOffset = 104;

  List<MenuCategory> _categories = [];
  List<MenuItem> _allMenus = [];
  String _activeCategory = 'all';
  String _search = '';
  bool _loading = false;
  String? _error;
  int _overlayCount = 0;
  final _menuScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _refreshAll();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybePromptTable());
  }

  @override
  void dispose() {
    _menuScrollController.dispose();
    super.dispose();
  }

  Future<T?> _withOverlay<T>(Future<T?> Function() show) async {
    setState(() => _overlayCount++);
    try {
      return await show();
    } finally {
      if (mounted) setState(() => _overlayCount--);
    }
  }

  void _openTablePicker() {
    _withOverlay(() => showTablePickerSheet(context, ref)).then((picked) async {
      if (!mounted || picked == null) return;
      final catMap = await ref.read(tableCategoryMapProvider.future);
      if (!mounted) return;
      final label = TableDisplay.tableLabel(picked, catMap);
      _showSnackBar('已选 $label', duration: const Duration(seconds: 1));
    });
  }

  void _showSnackBar(
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          duration: duration,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.fromLTRB(
            16,
            0,
            16,
            _snackBarBottomOffset + bottomPadding,
          ),
        ),
      );
  }

  void _maybePromptTable() {
    if (!mounted) return;
    if (ref.read(orderTypeProvider) == 'dine_in' &&
        ref.read(currentTableProvider) == null) {
      _openTablePicker();
    }
  }

  Future<void> _refreshAll({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final repo = ref.read(menuRepositoryProvider);
      final results = await Future.wait([
        repo.listCategories(),
        repo.listMenus(),
      ]);
      if (!mounted) return;
      final menus = results[1] as List<MenuItem>;
      setState(() {
        _categories = results[0] as List<MenuCategory>;
        _allMenus = menus;
        if (silent) _error = null;
      });
      MenuCoverImage.warmCache(context, menus);
    } on ApiException catch (e) {
      if (mounted && !silent) setState(() => _error = e.message);
    } finally {
      if (mounted && !silent) setState(() => _loading = false);
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
    // 有搜索词时在全量菜单中检索，不受左侧分类限制
    return _allMenus
        .where((m) => m.name.toLowerCase().contains(q))
        .toList();
  }

  bool get _isSearching => _search.trim().isNotEmpty;

  bool _ensureDineInTable() {
    if (ref.read(addToOrderProvider) != null) return true;
    if (ref.read(orderTypeProvider) != 'dine_in') return true;
    if (ref.read(currentTableProvider) != null) return true;
    _showSnackBar('堂食请先选择餐桌');
    _openTablePicker();
    return false;
  }

  void _openSpecPicker(MenuItem menu) {
    if (!_ensureDineInTable()) return;
    if (menu.specs.isEmpty) {
      _addToCart(menu, 1, []);
      return;
    }
    _withOverlay(
      () => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => SpecPickerSheet(
          menu: menu,
          onConfirm: (qty, specs) => _addToCart(menu, qty, specs),
        ),
      ),
    );
  }

  void _addToCart(MenuItem menu, int qty, List<MenuSpec> specs) {
    final delta = specs.fold<double>(0, (s, e) => s + e.priceDelta);
    final unit = menu.priceYuan + delta;
    final specInfo = specs.isEmpty
        ? null
        : specs.map((s) => '${s.specType}:${s.specValue}').join(' ');

    ref
        .read(cartProvider.notifier)
        .add(
          CartItem(
            menuId: menu.id,
            name: menu.name,
            unitPrice: unit,
            quantity: qty,
            specInfo: specInfo,
            image: menu.image,
          ),
        );
    _showSnackBar(
      '已添加 ${menu.name} ×$qty',
      duration: const Duration(seconds: 1),
    );
  }

  void _openCartSheet() {
    _withOverlay(
      () => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const CartSheet(),
      ),
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
      final q = _search.trim();
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 80),
          Icon(
            Icons.restaurant_outlined,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              q.isEmpty ? '暂无菜品' : '未找到「$q」',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          if (q.isNotEmpty) ...[
            const SizedBox(height: 4),
            const Center(
              child: Text(
                '已在全部菜品中搜索',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ),
          ],
        ],
      );
    }
    return ListView.separated(
      key: PageStorageKey<String>(
        _isSearching ? 'menu-search' : 'menu-$_activeCategory',
      ),
      controller: _menuScrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      itemCount: _filteredMenus.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final menu = _filteredMenus[index];
        return MenuListTile(
          key: ValueKey(menu.id),
          menu: menu,
          onAdd: () => _openSpecPicker(menu),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final addSession = ref.watch(addToOrderProvider);
    final isAddMode = addSession != null;

    return ShellTabListener(
      tabIndex: ShellTab.ordering,
      onReselect: () {
        if (_overlayCount > 0) return;
        _refreshAll(silent: true);
      },
      child: Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          OrderingHeader(
            initialQuery: _search,
            onSearchChanged: (v) => setState(() => _search = v),
          ),
          const AddToOrderBanner(),
          if (!isAddMode) OrderModeBar(onPickTable: _openTablePicker),
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
                    notificationPredicate: (notification) {
                      if (_overlayCount > 0) return false;
                      return notification.depth == 0;
                    },
                    child: _buildMenuPanel(),
                  ),
                ),
              ],
            ),
          ),
          _OrderingCartBar(
            onTap: _openCartSheet,
            onCheckout: _openCartSheet,
          ),
        ],
      ),
    ),
    );
  }
}

class _OrderingCartBar extends ConsumerWidget {
  const _OrderingCartBar({
    required this.onTap,
    required this.onCheckout,
  });

  final VoidCallback onTap;
  final VoidCallback onCheckout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final addSession = ref.watch(addToOrderProvider);
    final isAddMode = addSession != null;
    final cartCount = cart.fold<int>(0, (sum, item) => sum + item.quantity);
    final cartTotal = cart.fold<double>(0, (sum, item) => sum + item.lineTotal);

    return CartBottomBar(
      itemCount: cartCount,
      totalYuan: cartTotal,
      checkoutLabel: isAddMode ? '确认加菜' : '去结算',
      cartTitle: isAddMode ? '本次加菜' : null,
      onTap: onTap,
      onCheckout: onCheckout,
    );
  }
}
