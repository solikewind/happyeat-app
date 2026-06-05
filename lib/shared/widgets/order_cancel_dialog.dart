import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// 确认取消/删除订单（后端均为状态变更为 cancelled）。
Future<bool> confirmRemoveOrder(
  BuildContext context, {
  required bool isDelete,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(isDelete ? '删除订单' : '取消订单'),
      content: Text(
        isDelete
            ? '确定删除该已完成订单？\n\n'
                '删除后将从已完成列表中移除，可在「已取消」筛选中查看。'
            : '确定取消该订单？\n\n'
                '取消后订单状态变为「已取消」，默认列表中不再显示；'
                '可在「已取消」筛选中查看。',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('取消'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.error),
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('确定'),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// 兼容旧调用
Future<bool> confirmCancelOrder(BuildContext context) =>
    confirmRemoveOrder(context, isDelete: false);
