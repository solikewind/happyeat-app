import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_styles.dart';
import '../../../data/models/models.dart';
import '../../../data/models/table_category.dart';
import '../../../shared/providers/app_providers.dart';
import '../../../shared/utils/table_display.dart';
import '../../../shared/widgets/load_error_panel.dart';
import '../../../shared/widgets/table_compact_tile.dart';

/// 仅在点餐页弹出选桌（底部抽屉）；厅面 Tab 不做选桌
Future<TableItem?> showTablePickerSheet(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet<TableItem>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (ctx) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.62,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (_, scrollController) => TablePickerSheet(
        scrollController: scrollController,
        onSelected: (table) => Navigator.pop(ctx, table),
      ),
    ),
  );
}

class TablePickerSheet extends ConsumerStatefulWidget {
  const TablePickerSheet({
    super.key,
    required this.scrollController,
    required this.onSelected,
  });

  final ScrollController scrollController;
  final void Function(TableItem table) onSelected;

  @override
  ConsumerState<TablePickerSheet> createState() => _TablePickerSheetState();
}

class _TablePickerSheetState extends ConsumerState<TablePickerSheet> {
  List<TableItem> _tables = [];
  List<TableCategoryItem> _categories = [];
  bool _loading = true;
  String? _error;

  Map<String, String> get _categoryNameById =>
      TableDisplay.categoryNameById(_categories);

  Map<String, List<TableItem>> get _groupedTables =>
      TableDisplay.groupTables(_tables, _categoryNameById);

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
      final repo = ref.read(tableRepositoryProvider);
      final results = await Future.wait([
        repo.listTables(),
        repo.listTableCategories(),
      ]);
      if (mounted) {
        setState(() {
          _tables = results[0] as List<TableItem>;
          _categories = results[1] as List<TableCategoryItem>;
        });
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _pick(TableItem table) {
    ref.read(currentTableProvider.notifier).state = table;
    ref.read(orderTypeProvider.notifier).state = 'dine_in';
    widget.onSelected(table);
  }

  @override
  Widget build(BuildContext context) {
    final current = ref.watch(currentTableProvider);
    final currentLabel = current != null
        ? TableDisplay.tableLabel(current, _categoryNameById)
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Row(
            children: [
              const Text('选择餐桌', style: AppStyles.pageTitle),
              const Spacer(),
              if (currentLabel != null)
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('当前 $currentLabel'),
                ),
            ],
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? LoadErrorPanel(message: _error!, onRetry: _load)
              : _tables.isEmpty
              ? const Center(child: Text('暂无餐桌'))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: CustomScrollView(
                    controller: widget.scrollController,
                    slivers: [
                      for (final entry in _groupedTables.entries) ...[
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                            child: Text(
                              entry.key,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: AppStyles.textPrimary,
                              ),
                            ),
                          ),
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          sliver: SliverGrid(
                            gridDelegate: tableCompactGridDelegate,
                            delegate: SliverChildBuilderDelegate((
                              context,
                              index,
                            ) {
                              final table = entry.value[index];
                              return TableCompactTile(
                                table: table,
                                selected: current?.id == table.id,
                                onTap: () => _pick(table),
                              );
                            }, childCount: entry.value.length),
                          ),
                        ),
                      ],
                      const SliverToBoxAdapter(child: SizedBox(height: 16)),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}
