import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/models.dart';
import '../../data/models/table_category.dart';

/// 桌台状态（与后端 tablebase.api / ent schema 一致）
enum TableStatusKind { idle, using, reserved, cleaning, unknown }

class TableDisplay {
  TableDisplay._();

  static TableStatusKind kindOf(String status) {
    switch (status.trim().toLowerCase()) {
      case 'idle':
      case 'free':
        return TableStatusKind.idle;
      case 'using':
      case 'occupied':
        return TableStatusKind.using;
      case 'reserved':
        return TableStatusKind.reserved;
      case 'cleaning':
        return TableStatusKind.cleaning;
      default:
        return TableStatusKind.unknown;
    }
  }

  static String statusLabel(String status) {
    switch (kindOf(status)) {
      case TableStatusKind.idle:
        return '空闲';
      case TableStatusKind.using:
        return '使用中';
      case TableStatusKind.reserved:
        return '预留';
      case TableStatusKind.cleaning:
        return '清洁中';
      case TableStatusKind.unknown:
        return status.isEmpty ? '未知' : status;
    }
  }

  static Color statusColor(String status) {
    switch (kindOf(status)) {
      case TableStatusKind.idle:
        return AppColors.success;
      case TableStatusKind.using:
        return AppColors.error;
      case TableStatusKind.reserved:
        return AppColors.warning;
      case TableStatusKind.cleaning:
        return const Color(0xFF64748B);
      case TableStatusKind.unknown:
        return AppColors.textSecondary;
    }
  }

  static Color statusSurface(String status) {
    return statusColor(status).withValues(alpha: 0.1);
  }

  static IconData statusIcon(String status) {
    switch (kindOf(status)) {
      case TableStatusKind.idle:
        return Icons.check_circle_outline;
      case TableStatusKind.using:
        return Icons.people_outline;
      case TableStatusKind.reserved:
        return Icons.schedule;
      case TableStatusKind.cleaning:
        return Icons.cleaning_services_outlined;
      case TableStatusKind.unknown:
        return Icons.help_outline;
    }
  }

  /// 厅面看板展示用：后端桌态未同步时，有进行中订单则按「使用中」显示（仅 UI，不改桌台数据）。
  static String hallDisplayStatus(
    String tableStatus, {
    required bool hasActiveOrder,
  }) {
    if (!hasActiveOrder) return tableStatus;
    final kind = kindOf(tableStatus);
    if (kind == TableStatusKind.idle || kind == TableStatusKind.unknown) {
      return 'using';
    }
    return tableStatus;
  }

  static Map<String, String> categoryNameById(
    List<TableCategoryItem> categories,
  ) {
    return {for (final c in categories) c.id: c.name};
  }

  /// 展示：大厅-1（与订单 locationLabel 一致）
  static String tableLabel(
    TableItem table,
    Map<String, String> categoryNameById,
  ) {
    final cat = categoryNameById[table.categoryId]?.trim() ?? '';
    final code = table.code.trim();
    if (cat.isNotEmpty && code.isNotEmpty) return '$cat-$code';
    if (code.isNotEmpty) return code;
    if (cat.isNotEmpty) return cat;
    return '未命名';
  }

  static Map<String, List<TableItem>> groupTables(
    List<TableItem> tables,
    Map<String, String> categoryNameById, {
    List<TableCategoryItem>? categories,
  }) {
    final map = <String, List<TableItem>>{};
    for (final t in tables) {
      final name = categoryNameById[t.categoryId]?.trim();
      final key = (name != null && name.isNotEmpty) ? name : '未分类';
      map.putIfAbsent(key, () => []).add(t);
    }
    for (final list in map.values) {
      list.sort((a, b) {
        final cmp = a.sort.compareTo(b.sort);
        if (cmp != 0) return cmp;
        return a.code.compareTo(b.code);
      });
    }
    final sortByName = categories == null
        ? null
        : {for (final c in categories) c.name: c.sort};
    final entries = map.entries.toList()
      ..sort((a, b) {
        if (sortByName != null) {
          final sa = sortByName[a.key] ?? 1 << 30;
          final sb = sortByName[b.key] ?? 1 << 30;
          final cmp = sa.compareTo(sb);
          if (cmp != 0) return cmp;
        }
        return a.key.compareTo(b.key);
      });
    return Map.fromEntries(entries);
  }
}
