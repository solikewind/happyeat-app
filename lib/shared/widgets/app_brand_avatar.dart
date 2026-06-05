import 'package:flutter/material.dart';

/// HappyEat 品牌头像：黑底白字 H（登录、我的等共用）
class AppBrandAvatar extends StatelessWidget {
  const AppBrandAvatar({
    super.key,
    this.size = 56,
    this.borderRadius,
    this.showShadow = false,
  });

  final double size;
  final double? borderRadius;
  final bool showShadow;

  static const Color _background = Color(0xFF101828);

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? size * 0.28;
    final fontSize = size * 0.52;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _background,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.28),
                  blurRadius: size * 0.22,
                  offset: Offset(0, size * 0.1),
                ),
              ]
            : null,
      ),
      alignment: Alignment.center,
      child: Text(
        'H',
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          height: 1,
          letterSpacing: -1,
        ),
      ),
    );
  }
}
