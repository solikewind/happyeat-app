import 'package:flutter/material.dart';

import '../../../core/theme/app_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/money.dart';
import '../../../data/models/models.dart';
import '../../../shared/widgets/menu_cover_image.dart';

class MenuListTile extends StatelessWidget {
  const MenuListTile({
    super.key,
    required this.menu,
    required this.onAdd,
  });

  final MenuItem menu;
  final VoidCallback onAdd;

  static const double _addButtonSize = 36;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppStyles.surfaceCard(radius: AppStyles.radiusLg),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MenuCoverImage(
              menu: menu,
              size: MenuCoverImage.listTileSize,
              borderRadius: BorderRadius.circular(AppStyles.radiusMd),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: MenuCoverImage.listTileSize,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          menu.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: AppStyles.textPrimary,
                            height: 1.25,
                          ),
                        ),
                        if (menu.description != null &&
                            menu.description!.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            menu.description!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                        if (menu.specs.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            '可选规格',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.primary.withValues(alpha: 0.85),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Text(
                              Money.formatYuan(menu.priceYuan),
                              style: const TextStyle(
                                color: AppStyles.price,
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                height: 1.1,
                              ),
                            ),
                          ),
                          Material(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(10),
                            child: InkWell(
                              onTap: onAdd,
                              borderRadius: BorderRadius.circular(10),
                              child: const SizedBox(
                                width: _addButtonSize,
                                height: _addButtonSize,
                                child: Icon(
                                  Icons.add,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
