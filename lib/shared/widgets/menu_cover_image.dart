import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/models.dart';

/// 菜单封面图：稳定 cacheKey + 按展示尺寸解码，避免每次刷列表重下原图。
class MenuCoverImage extends StatelessWidget {
  const MenuCoverImage({
    super.key,
    required this.menu,
    this.size = 84,
    this.borderRadius,
  });

  static const double listTileSize = 84;

  final MenuItem menu;
  final double size;
  final BorderRadius? borderRadius;

  static String cacheKeyFor(MenuItem menu) {
    final objectId = menu.objectId;
    if (objectId != null && objectId.isNotEmpty) {
      return 'menu-cover-obj-$objectId';
    }
    return 'menu-cover-${menu.id}';
  }

  static int cachePixelSize(BuildContext context, double logicalSize) {
    final ratio = MediaQuery.devicePixelRatioOf(context);
    return (logicalSize * ratio).ceil().clamp(64, 512);
  }

  static CachedNetworkImageProvider provider(
    MenuItem menu, {
    required int cachePixelSize,
  }) {
    return CachedNetworkImageProvider(
      menu.image!,
      cacheKey: cacheKeyFor(menu),
      maxWidth: cachePixelSize,
      maxHeight: cachePixelSize,
    );
  }

  /// 菜单拉取后预加载封面，减轻首屏/滚动时「刷出来才显示」。
  static void warmCache(
    BuildContext context,
    List<MenuItem> menus, {
    int eagerCount = 24,
  }) {
    if (!context.mounted) return;
    final pixelSize = cachePixelSize(context, listTileSize);
    final withImage = menus
        .where((m) => m.image != null && m.image!.isNotEmpty)
        .toList();
    if (withImage.isEmpty) return;

    Future<void>(() async {
      for (var i = 0; i < withImage.length; i++) {
        if (!context.mounted) return;
        final menu = withImage[i];
        try {
          await precacheImage(
            provider(menu, cachePixelSize: pixelSize),
            context,
          );
        } catch (_) {
          // 单张失败不影响其余
        }
        if (i == eagerCount - 1) {
          await Future<void>.delayed(Duration.zero);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final url = menu.image;
    final image = ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: url != null && url.isNotEmpty
          ? CachedNetworkImage(
              width: size,
              height: size,
              fit: BoxFit.cover,
              imageUrl: url,
              cacheKey: cacheKeyFor(menu),
              memCacheWidth: cachePixelSize(context, size),
              memCacheHeight: cachePixelSize(context, size),
              maxWidthDiskCache: cachePixelSize(context, size),
              maxHeightDiskCache: cachePixelSize(context, size),
              fadeInDuration: const Duration(milliseconds: 180),
              fadeOutDuration: const Duration(milliseconds: 80),
              placeholder: (_, __) => _placeholder(size),
              errorWidget: (_, __, ___) => _placeholder(size),
            )
          : _placeholder(size),
    );
    return image;
  }

  static Widget _placeholder(double size) {
    return Container(
      width: size,
      height: size,
      color: AppColors.primaryLight,
      alignment: Alignment.center,
      child: Icon(
        Icons.restaurant_menu,
        color: AppColors.primary.withValues(alpha: 0.5),
        size: size * 0.36,
      ),
    );
  }
}
