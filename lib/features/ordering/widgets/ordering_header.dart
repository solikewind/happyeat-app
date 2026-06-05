import 'package:flutter/material.dart';

import '../../../core/theme/app_styles.dart';
import '../../../core/theme/app_theme.dart';

/// 点餐页顶部：紧凑搜索栏
class OrderingHeader extends StatefulWidget {
  const OrderingHeader({
    super.key,
    required this.onSearchChanged,
    this.initialQuery = '',
  });

  final ValueChanged<String> onSearchChanged;
  final String initialQuery;

  @override
  State<OrderingHeader> createState() => _OrderingHeaderState();
}

class _OrderingHeaderState extends State<OrderingHeader> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery);
  }

  @override
  void didUpdateWidget(OrderingHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialQuery != _controller.text) {
      _controller.text = widget.initialQuery;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _clear() {
    _controller.clear();
    widget.onSearchChanged('');
  }

  @override
  Widget build(BuildContext context) {
    final hasQuery = _controller.text.trim().isNotEmpty;

    return Material(
      color: Colors.white,
      child: SafeArea(
        bottom: false,
        child: Container(
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppStyles.border)),
          ),
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
          child: TextField(
            controller: _controller,
            onChanged: (v) {
              setState(() {});
              widget.onSearchChanged(v);
            },
            textInputAction: TextInputAction.search,
            style: const TextStyle(fontSize: 15),
            decoration: InputDecoration(
              hintText: '搜索全部菜品',
              hintStyle: TextStyle(
                color: AppColors.textSecondary.withValues(alpha: 0.85),
                fontSize: 14,
              ),
              prefixIcon: Icon(
                Icons.search_rounded,
                size: 22,
                color: AppColors.textSecondary.withValues(alpha: 0.75),
              ),
              suffixIcon: hasQuery
                  ? IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: _clear,
                      tooltip: '清除',
                    )
                  : null,
              filled: true,
              fillColor: AppStyles.surfaceMuted,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 11,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppStyles.radiusMd),
                borderSide: const BorderSide(color: AppStyles.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppStyles.radiusMd),
                borderSide: const BorderSide(color: AppStyles.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppStyles.radiusMd),
                borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
