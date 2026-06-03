import 'package:flutter/material.dart';

import 'app_theme.dart';

/// 间距、圆角、阴影等设计 token
class AppStyles {
  AppStyles._();

  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 20;

  static const Color border = Color(0xFFE8EDF5);
  static const Color surfaceMuted = Color(0xFFF7F9FC);
  static const Color textPrimary = Color(0xFF101828);
  static const Color price = Color(0xFFFF4D4F);
  static const Color cartBarBg = Color(0xFF1E293B);

  static const TextStyle pageTitle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: textPrimary,
    height: 1.2,
  );

  static const TextStyle pageSubtitle = TextStyle(
    fontSize: 12,
    color: AppColors.textSecondary,
    height: 1.3,
  );

  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: const Color(0xFF101828).withValues(alpha: 0.06),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];

  static BoxDecoration surfaceCard({Color? color, double radius = radiusMd}) {
    return BoxDecoration(
      color: color ?? Colors.white,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: border),
      boxShadow: cardShadow,
    );
  }

  static BoxDecoration sheetTop() {
    return const BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.vertical(top: Radius.circular(radiusXl)),
    );
  }
}
