import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_providers.dart';

/// 切回指定底栏 Tab 时触发 [onReselect]（含 programmatic 跳转）。
class ShellTabListener extends ConsumerStatefulWidget {
  const ShellTabListener({
    super.key,
    required this.tabIndex,
    required this.onReselect,
    required this.child,
  });

  final int tabIndex;
  final VoidCallback onReselect;
  final Widget child;

  @override
  ConsumerState<ShellTabListener> createState() => _ShellTabListenerState();
}

class _ShellTabListenerState extends ConsumerState<ShellTabListener> {
  @override
  void initState() {
    super.initState();
    ref.listenManual<int>(shellTabIndexProvider, (prev, next) {
      if (next == widget.tabIndex && prev != null && prev != next) {
        widget.onReselect();
      }
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
