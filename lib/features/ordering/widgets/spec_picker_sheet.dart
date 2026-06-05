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
  late List<MapEntry<String, List<MenuSpec>>> _specGroups;

  @override
  void initState() {
    super.initState();
    _selected = {};
    final byType = <String, List<MenuSpec>>{};
    for (final s in widget.menu.specs) {
      final t = s.specType ?? '规格';
      byType.putIfAbsent(t, () => []).add(s);
    }
    _specGroups = byType.entries.toList();
    for (final entry in _specGroups) {
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

  void _selectSpec(String group, MenuSpec spec) {
    if (_selected[group]?.specValue == spec.specValue) return;
    setState(() => _selected[group] = spec);
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.72;

    return Container(
      decoration: AppStyles.sheetTop(),
      constraints: BoxConstraints(maxHeight: maxHeight),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
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
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final entry in _specGroups) ...[
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
                        final selected =
                            _selected[entry.key]?.specValue == spec.specValue;
                        return _SpecOptionChip(
                          key: ValueKey('${entry.key}-${spec.specValue}'),
                          label:
                              '${spec.label}${Money.formatDeltaYuan(spec.priceDelta)}',
                          selected: selected,
                          onTap: () => _selectSpec(entry.key, spec),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
            ),
          ),
          Row(
            children: [
              const Text('数量'),
              const Spacer(),
              _QtyStepButton(
                icon: Icons.remove,
                enabled: _qty > 1,
                onTap: () => setState(() => _qty--),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text('$_qty', style: const TextStyle(fontSize: 16)),
              ),
              _QtyStepButton(
                icon: Icons.add,
                enabled: _qty < 99,
                onTap: () => setState(() => _qty++),
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

class _SpecOptionChip extends StatelessWidget {
  const _SpecOptionChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppColors.primary.withValues(alpha: 0.12)
          : AppStyles.surfaceMuted,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? AppColors.primary : AppStyles.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              color: selected ? AppColors.primary : AppStyles.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _QtyStepButton extends StatelessWidget {
  const _QtyStepButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: enabled ? AppStyles.surfaceMuted : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(
            icon,
            size: 20,
            color: enabled ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
