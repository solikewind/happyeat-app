import '../../data/models/models.dart';
import '../../core/utils/money.dart';

/// 合并原单明细与本次加菜购物车，生成 PUT /order/:id 所需 items
class OrderUpdateItems {
  OrderUpdateItems._();

  static String _lineKey({
    String? menuId,
    required String menuName,
    String? specInfo,
    double? unitPrice,
  }) {
    final spec = specInfo?.trim() ?? '';
    if (menuId != null && menuId.isNotEmpty) {
      return 'id:$menuId|$spec';
    }
    return 'name:$menuName|$spec|${unitPrice ?? 0}';
  }

  /// [menuNameToId] 由菜单列表构建，用于把历史订单行映射到 menu_id
  static List<Map<String, dynamic>> mergeForUpdate({
    required List<OrderLineItem> existing,
    required List<CartItem> additions,
    required Map<String, String> menuNameToId,
  }) {
    final merged = <String, _MergedLine>{};

    void put(_MergedLine line) {
      final key = _lineKey(
        menuId: line.menuId,
        menuName: line.menuName,
        specInfo: line.specInfo,
        unitPrice: line.unitPrice,
      );
      final prev = merged[key];
      if (prev == null) {
        merged[key] = line;
      } else {
        merged[key] = prev.copyWith(quantity: prev.quantity + line.quantity);
      }
    }

    for (final item in existing) {
      final menuId = menuNameToId[item.menuName];
      put(
        _MergedLine(
          menuId: menuId,
          menuName: item.menuName,
          unitPrice: item.unitPrice,
          quantity: item.quantity,
          specInfo: item.specInfo,
        ),
      );
    }

    for (final item in additions) {
      put(
        _MergedLine(
          menuId: item.menuId,
          menuName: item.name,
          unitPrice: item.unitPrice,
          quantity: item.quantity,
          specInfo: item.specInfo,
        ),
      );
    }

    return merged.values.map((l) => l.toJson()).toList();
  }
}

class _MergedLine {
  _MergedLine({
    this.menuId,
    required this.menuName,
    required this.unitPrice,
    required this.quantity,
    this.specInfo,
  });

  final String? menuId;
  final String menuName;
  final double unitPrice;
  final int quantity;
  final String? specInfo;

  _MergedLine copyWith({int? quantity}) {
    return _MergedLine(
      menuId: menuId,
      menuName: menuName,
      unitPrice: unitPrice,
      quantity: quantity ?? this.quantity,
      specInfo: specInfo,
    );
  }

  Map<String, dynamic> toJson() {
    final spec = specInfo?.trim();
    final hasMenuId = menuId != null && menuId!.isNotEmpty;
    if (hasMenuId) {
      return {
        'menu_id': menuId,
        'quantity': quantity,
        'unit_price': Money.yuanToApiInt(unitPrice),
        if (spec != null && spec.isNotEmpty) 'spec_info': spec,
      };
    }
    return {
      'menu_name': menuName,
      'quantity': quantity,
      'unit_price': Money.yuanToApiInt(unitPrice),
      if (spec != null && spec.isNotEmpty) 'spec_info': spec,
    };
  }
}
