import 'package:flutter/material.dart';

import '../../../core/theme/app_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/money.dart';
import '../../../data/models/models.dart';

class SpecPickerSheet extends StatefulWidget {
  const SpecPickerSheet({
    super.key,
    required this.menu,
    required this.onConfirm,
  });

  final MenuItem menu;
  final void Function(int quantity, List<MenuSpec> specs) onConfirm;

  @override
  State<SpecPickerSheet> createState() => _SpecPickerSheetState();
}

class _SpecPickerSheetState extends State<SpecPickerSheet> {
  int _qty = 1;
  late Map<String, MenuSpec> _selected;

  @override
  void initState() {
    super.initState();
    _selected = {};
    final byType = <String, List<MenuSpec>>{};
    for (final s in widget.menu.specs) {
      final t = s.specType ?? '规格';
      byType.putIfAbsent(t, () => []).add(s);
    }
    for (final entry in byType.entries) {
      if (entry.value.isNotEmpty) {
        _selected[entry.key] = entry.value.first;
      }
    }
  }

  double get _unitPrice {
    final delta = _selected.values.fold<double>(
      0,
      (sum, s) => sum + s.priceDelta,
    );
    return widget.menu.priceYuan + delta;
  }

  @override
  Widget build(BuildContext context) {
    final byType = <String, List<MenuSpec>>{};
    for (final s in widget.menu.specs) {
      final t = s.specType ?? '规格';
      byType.putIfAbsent(t, () => []).add(s);
    }

    return Container(
      decoration: AppStyles.sheetTop(),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(
            widget.menu.name,
            style: AppStyles.pageTitle.copyWith(fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            Money.formatYuan(_unitPrice),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppStyles.price,
            ),
          ),
          const SizedBox(height: 16),
          for (final entry in byType.entries) ...[
            Text(
              entry.key,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: entry.value.map((spec) {
                final selected = _selected[entry.key]?.specValue == spec.specValue;
                return ChoiceChip(
                  label: Text(
                    '${spec.label}${Money.formatDeltaYuan(spec.priceDelta)}',
                  ),
                  selected: selected,
                  onSelected: (_) {
                    setState(() => _selected[entry.key] = spec);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              const Text('数量'),
              const Spacer(),
              IconButton(
                onPressed: _qty > 1 ? () => setState(() => _qty--) : null,
                icon: const Icon(Icons.remove_circle_outline),
              ),
              Text('$_qty', style: const TextStyle(fontSize: 16)),
              IconButton(
                onPressed: _qty < 99 ? () => setState(() => _qty++) : null,
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () {
              widget.onConfirm(_qty, _selected.values.toList());
              Navigator.pop(context);
            },
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
            child: Text('加入购物车 · ${Money.formatYuan(_unitPrice * _qty)}'),
          ),
        ],
      ),
    );
  }
}
