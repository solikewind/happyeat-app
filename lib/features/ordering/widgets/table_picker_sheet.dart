import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/models.dart';
import '../../../shared/providers/app_providers.dart';
import '../../../shared/utils/table_display.dart';
import '../../../shared/widgets/load_error_panel.dart';

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
  bool _loading = true;
  String? _error;

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
      final list = await ref.read(tableRepositoryProvider).listTables();
      if (mounted) setState(() => _tables = list);
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Row(
            children: [
              const Text('选择餐桌', style: AppStyles.pageTitle),
              const Spacer(),
              if (current != null)
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('当前 ${current.code}'),
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
                          child: GridView.builder(
                            controller: widget.scrollController,
                            padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 4,
                              mainAxisSpacing: 8,
                              crossAxisSpacing: 8,
                              childAspectRatio: 0.95,
                            ),
                            itemCount: _tables.length,
                            itemBuilder: (context, index) {
                              final table = _tables[index];
                              return _TablePickTile(
                                table: table,
                                selected: current?.id == table.id,
                                onTap: () => _pick(table),
                              );
                            },
                          ),
                        ),
        ),
      ],
    );
  }
}

class _TablePickTile extends StatelessWidget {
  const _TablePickTile({
    required this.table,
    required this.selected,
    required this.onTap,
  });

  final TableItem table;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final statusColor = TableDisplay.statusColor(table.status);

    return Material(
      color: selected ? AppColors.primaryLight : Colors.white,
      borderRadius: BorderRadius.circular(AppStyles.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppStyles.radiusMd),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppStyles.radiusMd),
            border: Border.all(
              color: selected ? AppColors.primary : AppStyles.border,
              width: selected ? 2 : 1,
            ),
            boxShadow: selected ? AppStyles.cardShadow : null,
          ),
          padding: const EdgeInsets.all(6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                table.code,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: selected ? AppColors.primary : null,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${table.capacity}人',
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  TableDisplay.statusLabel(table.status),
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
