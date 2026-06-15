import 'package:flutter/widgets.dart';

import 'order_swipe_group.dart';

/// 在订单列表外层注入，供 [OrderSwipeActions] 互斥展开 / 滚动收回。
class OrderSwipeScope extends InheritedWidget {
  const OrderSwipeScope({
    super.key,
    required this.group,
    required super.child,
  });

  final OrderSwipeGroup group;

  static OrderSwipeGroup? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<OrderSwipeScope>()
        ?.group;
  }

  @override
  bool updateShouldNotify(OrderSwipeScope oldWidget) =>
      !identical(group, oldWidget.group);
}
