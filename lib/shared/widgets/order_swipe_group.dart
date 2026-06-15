import 'package:flutter/foundation.dart';

/// 订单列表左滑互斥：同时只展开一条，滚动时全部收回。
class OrderSwipeGroup extends ChangeNotifier {
  VoidCallback? _closeOpen;

  void open(VoidCallback close) {
    if (_closeOpen != null && _closeOpen != close) {
      _closeOpen!();
    }
    _closeOpen = close;
  }

  void closeCurrent() {
    _closeOpen?.call();
    _closeOpen = null;
  }

  void release(VoidCallback close) {
    if (_closeOpen == close) _closeOpen = null;
  }
}
