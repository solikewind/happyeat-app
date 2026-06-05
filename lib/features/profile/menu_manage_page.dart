import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/money.dart';
import '../../data/models/models.dart';
import '../../shared/providers/app_providers.dart';
import '../../shared/widgets/load_error_panel.dart';
import '../../shared/widgets/menu_cover_image.dart';
import '../ordering/widgets/ordering_header.dart';

class MenuManagePage extends ConsumerStatefulWidget {
  const MenuManagePage({super.key});

  @override
  ConsumerState<MenuManagePage> createState() => _MenuManagePageState();
}

class _MenuManagePageState extends ConsumerState<MenuManagePage> {
  List<MenuItem> _menus = [];
  Map<String, String> _categoryNames = {};
  bool _loading = true;
  String? _error;
  String _search = '';

  List<MenuItem> get _filteredMenus {
    final q = _search.trim().toLowerCase();
    if (q.isEmpty) return _menus;
    return _menus.where((m) {
      final name = m.name.toLowerCase();
      final category = (_categoryNames[m.categoryId] ?? '').toLowerCase();
      return name.contains(q) || category.contains(q);
    }).toList();
  }

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
      final repo = ref.read(menuRepositoryProvider);
      final results = await Future.wait([
        repo.listCategories(),
        repo.listMenus(),
      ]);
      final categories = results[0] as List<MenuCategory>;
      final menus = results[1] as List<MenuItem>;
      if (!mounted) return;
      setState(() {
        _categoryNames = {for (final c in categories) c.id: c.name};
        _menus = menus;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openEditor({String? menuId}) async {
    final changed = await context.push<bool>(
      '/menu-edit',
      extra: menuId,
    );
    if (changed == true) await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('菜单管理')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(),
        icon: const Icon(Icons.add),
        label: const Text('添加菜品'),
      ),
      body: Column(
        children: [
          OrderingHeader(
            initialQuery: _search,
            onSearchChanged: (v) => setState(() => _search = v),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return LoadErrorPanel(message: _error!, onRetry: _load);
    }
    if (_menus.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 120),
          Center(child: Text('暂无菜品，点击右下角添加')),
        ],
      );
    }
    final filtered = _filteredMenus;
    if (filtered.isEmpty) {
      final q = _search.trim();
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 80),
          Icon(
            Icons.search_off_rounded,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              '未找到「$q」',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ],
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 88),
        itemCount: filtered.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final menu = filtered[index];
          final category = _categoryNames[menu.categoryId] ?? '未分类';
          return Card(
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => _openEditor(menuId: menu.id),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    MenuCoverImage(
                      menu: menu,
                      size: 56,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            menu.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            category,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            Money.formatYuan(menu.priceYuan),
                            style: const TextStyle(
                              color: AppColors.error,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
