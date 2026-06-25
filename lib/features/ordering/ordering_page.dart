import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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
import 'widgets/menu_section_header.dart';
import 'widgets/order_mode_bar.dart';
import 'widgets/ordering_header.dart';
import 'widgets/spec_picker_sheet.dart';
import 'widgets/table_picker_sheet.dart';

class _MenuSection {
  const _MenuSection({
    required this.categoryKey,
    required this.title,
    required this.items,
  });

  final String categoryKey;
  final String title;
  final List<MenuItem> items;
}

class _MenuListEntry {
  const _MenuListEntry.header(this.section) : menu = null;

  const _MenuListEntry.item(this.menu) : section = null;

  final _MenuSection? section;
  final MenuItem? menu;

  bool get isHeader => section != null;
}

class OrderingPage extends ConsumerStatefulWidget {
  const OrderingPage({super.key});

  @override
  ConsumerState<OrderingPage> createState() => _OrderingPageState();
}

class _OrderingPageState extends ConsumerState<OrderingPage> {
  static const double _snackBarHorizontalMargin = 16;
  static const double _snackBarMaxWidth = 280;
  static const double _snackBarMinVisibleBottomGap = 56;
  static const double _snackBarTopRatio = 0.36;
  static const double _sectionSyncThreshold = 132;
  static const double _listPaddingTop = 8;
  static const double _sectionHeaderHeight = 36;
  static const double _menuItemBaseHeight = 104;
  static const double _menuItemDescExtra = 14;
  static const double _menuItemSpecsExtra = 15;
  static const double _menuItemGap = 10;
  static const double _sectionEndGap = 4;

  List<MenuCategory> _categories = [];
  List<MenuItem> _allMenus = [];
  String _activeCategory = 'all';
  String _searchInput = '';
  String _search = '';
  int _searchClearToken = 0;
  bool _loading = false;
  String? _error;
  int _overlayCount = 0;
  bool _scrollFromRail = false;
  OverlayEntry? _snackOverlay;
  Timer? _snackOverlayTimer;

  final _menuScrollController = ScrollController();
  final Map<String, GlobalKey> _sectionHeaderKeys = {};
  final Map<String, GlobalKey> _menuItemKeys = {};

  @override
  void initState() {
    super.initState();
    _menuScrollController.addListener(_handleMenuScroll);
    _refreshAll();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybePromptTable());
  }

  @override
  void dispose() {
    _dismissSnackOverlay();
    _menuScrollController.removeListener(_handleMenuScroll);
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
    _dismissSnackOverlay();
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;

    final entry = OverlayEntry(
      builder: (context) {
        final media = MediaQuery.of(context);
        final visibleHeight = media.size.height - media.viewInsets.bottom;
        final minTop = media.padding.top + 12;
        final maxTop = (visibleHeight - _snackBarMinVisibleBottomGap)
            .clamp(minTop, media.size.height)
            .toDouble();
        final top = (media.padding.top + visibleHeight * _snackBarTopRatio)
            .clamp(minTop, maxTop)
            .toDouble();

        return Positioned(
          top: top,
          left: _snackBarHorizontalMargin,
          right: _snackBarHorizontalMargin,
          child: IgnorePointer(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: _snackBarMaxWidth),
                child: Material(
                  color: Colors.black.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(999),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    child: Text(
                      message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
    _snackOverlay = entry;
    overlay.insert(entry);
    _snackOverlayTimer = Timer(duration, _dismissSnackOverlay);
  }

  void _dismissSnackOverlay() {
    _snackOverlayTimer?.cancel();
    _snackOverlayTimer = null;
    _snackOverlay?.remove();
    _snackOverlay = null;
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

  List<MenuCategory> get _sortedCategories {
    final list = List<MenuCategory>.from(_categories);
    list.sort((a, b) {
      final cmp = a.sort.compareTo(b.sort);
      if (cmp != 0) return cmp;
      return a.id.compareTo(b.id);
    });
    return list;
  }

  Map<String, String> get _categoryNameById {
    return {for (final c in _categories) c.id: c.name};
  }

  Map<String, int> get _categorySortById {
    return {for (final c in _categories) c.id: c.sort};
  }

  List<MenuItem> _sortedMenus(
    List<MenuItem> list, {
    required bool groupByCategory,
  }) {
    return List<MenuItem>.from(list)..sort((a, b) {
      if (groupByCategory) {
        final catCmp = (_categorySortById[a.categoryId] ?? (1 << 30)).compareTo(
          _categorySortById[b.categoryId] ?? (1 << 30),
        );
        if (catCmp != 0) return catCmp;
        final nameCmp = (_categoryNameById[a.categoryId] ?? '').compareTo(
          _categoryNameById[b.categoryId] ?? '',
        );
        if (nameCmp != 0) return nameCmp;
      }
      final cmp = a.sort.compareTo(b.sort);
      if (cmp != 0) return cmp;
      return a.id.compareTo(b.id);
    });
  }

  List<MenuItem> get _filteredMenus {
    final q = _search.trim().toLowerCase();
    if (q.isEmpty) return _sortedMenus(_allMenus, groupByCategory: true);
    final matched = _allMenus
        .where((m) => m.name.toLowerCase().contains(q))
        .toList();
    return _sortedMenus(matched, groupByCategory: true);
  }

  List<_MenuSection> get _menuSections {
    final menus = _filteredMenus;
    final grouped = <String, List<MenuItem>>{};
    for (final menu in menus) {
      final name = _categoryNameById[menu.categoryId] ?? '未分类';
      grouped.putIfAbsent(name, () => []).add(menu);
    }

    final sections = <_MenuSection>[];
    final used = <String>{};

    for (final cat in _sortedCategories) {
      final items = grouped[cat.name];
      if (items == null || items.isEmpty) continue;
      used.add(cat.name);
      sections.add(
        _MenuSection(categoryKey: cat.name, title: cat.name, items: items),
      );
    }

    for (final entry in grouped.entries) {
      if (used.contains(entry.key)) continue;
      sections.add(
        _MenuSection(
          categoryKey: entry.key,
          title: entry.key,
          items: entry.value,
        ),
      );
    }
    return sections;
  }

  List<_MenuListEntry> _flatMenuEntries(List<_MenuSection> sections) {
    final entries = <_MenuListEntry>[];
    for (final section in sections) {
      entries.add(_MenuListEntry.header(section));
      for (final menu in section.items) {
        entries.add(_MenuListEntry.item(menu));
      }
    }
    return entries;
  }

  void _ensureSectionHeaderKeys(List<_MenuSection> sections) {
    final keys = sections.map((s) => s.categoryKey).toSet();
    for (final key in keys) {
      _sectionHeaderKeys.putIfAbsent(key, GlobalKey.new);
    }
    _sectionHeaderKeys.removeWhere((key, _) => !keys.contains(key));
  }

  void _ensureMenuItemKeys(List<_MenuSection> sections) {
    final keys = {
      for (final section in sections)
        for (final menu in section.items) menu.id,
    };
    for (final key in keys) {
      _menuItemKeys.putIfAbsent(key, GlobalKey.new);
    }
    _menuItemKeys.removeWhere((key, _) => !keys.contains(key));
  }

  void _handleMenuScroll() {
    if (_scrollFromRail || !_menuScrollController.hasClients) return;
    _syncActiveCategoryFromScroll();
  }

  void _syncActiveCategoryFromScroll() {
    final sections = _menuSections;
    if (sections.isEmpty) return;

    if (_menuScrollController.offset <= 8) {
      _setActiveCategory('all');
      return;
    }

    String? current;
    for (final section in sections) {
      final ctx = _sectionHeaderKeys[section.categoryKey]?.currentContext;
      if (ctx == null) continue;
      final render = ctx.findRenderObject();
      if (render is! RenderBox || !render.hasSize) continue;
      final top = render.localToGlobal(Offset.zero).dy;
      if (top <= _sectionSyncThreshold) {
        current = section.categoryKey;
      }
    }

    if (current != null) {
      _setActiveCategory(current);
    }
  }

  void _setActiveCategory(String key) {
    if (_activeCategory == key) return;
    setState(() => _activeCategory = key);
  }

  double _estimatedEntryHeight(_MenuListEntry entry) {
    if (entry.isHeader) return _sectionHeaderHeight;
    final menu = entry.menu!;
    var height = _menuItemBaseHeight;
    if (menu.description != null && menu.description!.isNotEmpty) {
      height += _menuItemDescExtra;
    }
    if (menu.specs.isNotEmpty) {
      height += _menuItemSpecsExtra;
    }
    return height;
  }

  double? _estimatedScrollOffsetForSection(String key) {
    final entries = _flatMenuEntries(_menuSections);
    var offset = _listPaddingTop;

    for (var index = 0; index < entries.length; index++) {
      final entry = entries[index];
      if (entry.isHeader && entry.section!.categoryKey == key) {
        return offset;
      }

      offset += _estimatedEntryHeight(entry);
      if (index + 1 < entries.length) {
        if (!entry.isHeader && entries[index + 1].isHeader) {
          offset += _sectionEndGap;
        } else if (!entry.isHeader) {
          offset += _menuItemGap;
        }
      }
    }
    return null;
  }

  double? _estimatedScrollOffsetForMenu(String menuId) {
    final entries = _flatMenuEntries(_menuSections);
    var offset = _listPaddingTop;

    for (var index = 0; index < entries.length; index++) {
      final entry = entries[index];
      if (!entry.isHeader && entry.menu!.id == menuId) {
        return offset;
      }

      offset += _estimatedEntryHeight(entry);
      if (index + 1 < entries.length) {
        if (!entry.isHeader && entries[index + 1].isHeader) {
          offset += _sectionEndGap;
        } else if (!entry.isHeader) {
          offset += _menuItemGap;
        }
      }
    }
    return null;
  }

  double? _measuredScrollOffsetForSection(String key) {
    final ctx = _sectionHeaderKeys[key]?.currentContext;
    if (ctx == null) return null;

    final renderObject = ctx.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) return null;

    final viewport = RenderAbstractViewport.of(renderObject);
    return viewport.getOffsetToReveal(renderObject, 0).offset;
  }

  double? _measuredScrollOffsetForMenu(String menuId) {
    final ctx = _menuItemKeys[menuId]?.currentContext;
    if (ctx == null) return null;

    final renderObject = ctx.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) return null;

    final viewport = RenderAbstractViewport.of(renderObject);
    return viewport.getOffsetToReveal(renderObject, 0.14).offset;
  }

  double _clampScrollOffset(double offset) {
    final position = _menuScrollController.position;
    return offset.clamp(0.0, position.maxScrollExtent);
  }

  Duration _scrollDurationFor(double targetOffset) {
    if (!_menuScrollController.hasClients) {
      return const Duration(milliseconds: 260);
    }
    final distance =
        (_clampScrollOffset(targetOffset) - _menuScrollController.offset).abs();
    final millis = (180 + distance * 0.18).clamp(220.0, 520.0).round();
    return Duration(milliseconds: millis);
  }

  Future<void> _animateMenuScrollTo(
    double offset, {
    Duration? duration,
    Curve curve = Curves.easeOutCubic,
  }) {
    return _menuScrollController.animateTo(
      _clampScrollOffset(offset),
      duration: duration ?? _scrollDurationFor(offset),
      curve: curve,
    );
  }

  Future<void> _scrollToSection(String key) async {
    if (!_menuScrollController.hasClients) return;

    _scrollFromRail = true;
    try {
      if (key == 'all') {
        await _animateMenuScrollTo(0);
        return;
      }

      var targetOffset =
          _measuredScrollOffsetForSection(key) ??
          _estimatedScrollOffsetForSection(key);
      if (targetOffset == null) return;

      await _animateMenuScrollTo(targetOffset);

      // 懒加载列表里目标标题可能尚未构建，先滚到估算位置再精确对齐。
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted || !_menuScrollController.hasClients) return;

      final refinedOffset = _measuredScrollOffsetForSection(key);
      if (refinedOffset == null) return;

      final delta = (refinedOffset - _menuScrollController.offset).abs();
      if (delta >= 1) {
        await _animateMenuScrollTo(refinedOffset);
      }
    } finally {
      _scrollFromRail = false;
    }
  }

  Future<void> _scrollToMenu(String menuId) async {
    if (!_menuScrollController.hasClients) return;
    final targetOffset = _estimatedScrollOffsetForMenu(menuId);
    if (targetOffset == null) return;

    _scrollFromRail = true;
    try {
      await _animateMenuScrollTo(targetOffset);
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;

      final refinedOffset = _measuredScrollOffsetForMenu(menuId);
      if (refinedOffset != null) {
        final delta = (refinedOffset - _menuScrollController.offset).abs();
        if (delta >= 12) {
          await _animateMenuScrollTo(
            refinedOffset,
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
          );
        }
      } else {
        final targetContext = _menuItemKeys[menuId]?.currentContext;
        if (targetContext != null) {
          await Scrollable.ensureVisible(
            targetContext,
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            alignment: 0.14,
          );
        }
      }
    } finally {
      _scrollFromRail = false;
    }
    _syncActiveCategoryFromScroll();
  }

  Future<void> _onCategorySelected(String key) async {
    _setActiveCategory(key);
    await _scrollToSection(key);
  }

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
    _clearSearchAfterMenuAdded(menu);
    _showSnackBar(
      '已添加 ${menu.name} ×$qty',
      duration: const Duration(seconds: 1),
    );
  }

  void _clearSearchAfterMenuAdded(MenuItem menu) {
    if (_searchInput.trim().isEmpty && _search.trim().isEmpty) return;
    setState(() {
      _searchInput = '';
      _search = '';
      _searchClearToken++;
      _activeCategory = 'all';
    });
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || !_menuScrollController.hasClients) return;
      await _scrollToMenu(menu.id);
    });
  }

  void _openCartSheet() {
    _withOverlay(
      () => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (_) => CartSheet(
          onPlacedNewOrder: () {
            if (ref.read(orderTypeProvider) == 'dine_in') {
              clearSelectedTable(ref);
            }
          },
        ),
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

    final sections = _menuSections;
    _ensureSectionHeaderKeys(sections);
    _ensureMenuItemKeys(sections);

    if (sections.isEmpty) {
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

    final entries = _flatMenuEntries(sections);

    return CustomScrollView(
      key: const PageStorageKey<String>('menu-sectioned'),
      controller: _menuScrollController,
      cacheExtent: 1200,
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final entry = entries[index];
              if (entry.isHeader) {
                final section = entry.section!;
                return MenuSectionHeader(
                  key: _sectionHeaderKeys[section.categoryKey],
                  title: section.title,
                  count: section.items.length,
                );
              }
              final menu = entry.menu!;
              final isLastInSection =
                  index + 1 >= entries.length || entries[index + 1].isHeader;
              return Padding(
                key: _menuItemKeys[menu.id],
                padding: EdgeInsets.only(bottom: isLastInSection ? 4 : 10),
                child: MenuListTile(
                  menu: menu,
                  onAdd: () => _openSpecPicker(menu),
                ),
              );
            }, childCount: entries.length),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final addSession = ref.watch(addToOrderProvider);
    final isAddMode = addSession != null;
    final railCategories = _sortedCategories.map((c) => c.name).toList();

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
              initialQuery: _searchInput,
              clearToken: _searchClearToken,
              onSearchChanged: (v) {
                final willSearch = v.trim().isNotEmpty;
                setState(() {
                  _searchInput = v;
                  _search = v;
                });

                if (willSearch && _menuScrollController.hasClients) {
                  _menuScrollController.jumpTo(0);
                  _setActiveCategory('all');
                }
              },
            ),
            const AddToOrderBanner(),
            if (!isAddMode) OrderModeBar(onPickTable: _openTablePicker),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CategoryRail(
                    categories: railCategories,
                    activeKey: _activeCategory,
                    onSelected: _onCategorySelected,
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
            _OrderingCartBar(onTap: _openCartSheet, onCheckout: _openCartSheet),
          ],
        ),
      ),
    );
  }
}

class _OrderingCartBar extends ConsumerWidget {
  const _OrderingCartBar({required this.onTap, required this.onCheckout});

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
