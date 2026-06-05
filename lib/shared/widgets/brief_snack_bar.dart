import 'package:flutter/material.dart';

/// 短提示（约 1.2 秒），用于订单状态变更等轻量反馈。
void showBriefSnackBar(
  BuildContext context,
  String message, {
  Duration duration = const Duration(milliseconds: 1200),
}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration,
        behavior: SnackBarBehavior.floating,
      ),
    );
}
