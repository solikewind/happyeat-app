import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// 桌台状态（与后端 tablebase.api / ent schema 一致）
enum TableStatusKind {
  idle,
  using,
  reserved,
  cleaning,
  unknown,
}

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
}
