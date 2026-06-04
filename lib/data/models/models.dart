import '../../core/utils/money.dart';

class LoginResult {
  LoginResult({
    required this.accessToken,
    required this.expire,
    this.userCode,
    this.role,
    this.roles = const [],
  });

  final String accessToken;
  final int expire;
  final String? userCode;
  final String? role;
  final List<String> roles;

  factory LoginResult.fromJson(Map<String, dynamic> json) {
    final rolesRaw = json['roles'];
    return LoginResult(
      accessToken: json['access_token'] as String? ?? '',
      expire: (json['expire'] as num?)?.toInt() ?? 0,
      userCode: json['user_code'] as String?,
      role: json['role'] as String?,
      roles: rolesRaw is List ? rolesRaw.map((e) => '$e').toList() : const [],
    );
  }
}

class MenuCategory {
  MenuCategory({
    required this.id,
    required this.name,
    this.description,
    this.sort = 0,
  });

  final String id;
  final String name;
  final String? description;
  final int sort;

  factory MenuCategory.fromJson(Map<String, dynamic> json) {
    return MenuCategory(
      id: '${json['id']}',
      name: '${json['name'] ?? ''}',
      description: json['description'] as String?,
      sort: (json['sort'] as num?)?.toInt() ?? 0,
    );
  }
}

class MenuSpec {
  MenuSpec({this.specType, this.specValue, this.priceDelta = 0});

  final String? specType;
  final String? specValue;
  final double priceDelta;

  factory MenuSpec.fromJson(Map<String, dynamic> json) {
    return MenuSpec(
      specType: json['spec_type'] as String?,
      specValue: json['spec_value'] as String?,
      priceDelta: Money.apiAmountToYuan((json['price_delta'] as num?) ?? 0),
    );
  }

  String get label => specValue ?? '默认';
}

class MenuItem {
  MenuItem({
    required this.id,
    required this.name,
    required this.priceYuan,
    required this.categoryId,
    this.description,
    this.image,
    this.specs = const [],
  });

  final String id;
  final String name;
  final double priceYuan;
  final String categoryId;
  final String? description;
  final String? image;
  final List<MenuSpec> specs;

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    final specsRaw = json['specs'];
    return MenuItem(
      id: '${json['id']}',
      name: '${json['name'] ?? ''}',
      priceYuan: Money.apiAmountToYuan((json['price'] as num?) ?? 0),
      categoryId: '${json['category_id'] ?? ''}',
      description: json['description'] as String?,
      image: json['image'] as String?,
      specs: specsRaw is List
          ? specsRaw
                .map((e) => MenuSpec.fromJson(e as Map<String, dynamic>))
                .toList()
          : [],
    );
  }
}

class TableItem {
  TableItem({
    required this.id,
    required this.code,
    required this.status,
    required this.capacity,
    required this.categoryId,
  });

  final String id;
  final String code;
  final String status;
  final int capacity;
  final String categoryId;

  factory TableItem.fromJson(Map<String, dynamic> json) {
    return TableItem(
      id: '${json['id']}',
      code: '${json['code'] ?? ''}',
      status: '${json['status'] ?? 'idle'}',
      capacity: (json['capacity'] as num?)?.toInt() ?? 0,
      categoryId: '${json['category_id'] ?? ''}',
    );
  }
}

class OrderLineItem {
  OrderLineItem({
    required this.menuName,
    required this.quantity,
    required this.unitPrice,
    this.specInfo,
    this.amount = 0,
  });

  final String menuName;
  final int quantity;
  final double unitPrice;
  final String? specInfo;
  final double amount;

  factory OrderLineItem.fromJson(Map<String, dynamic> json) {
    return OrderLineItem(
      menuName: '${json['menu_name'] ?? ''}',
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      unitPrice: Money.apiAmountToYuan((json['unit_price'] as num?) ?? 0),
      specInfo: json['spec_info'] as String?,
      amount: Money.apiAmountToYuan((json['amount'] as num?) ?? 0),
    );
  }
}

class OrderModel {
  OrderModel({
    required this.id,
    required this.orderNo,
    required this.status,
    required this.orderType,
    required this.totalAmount,
    this.actualAmount,
    this.tableId,
    this.tableCode,
    this.tableCategory,
    this.remark,
    this.items = const [],
    this.createdAt,
  });

  final String id;
  final String orderNo;
  final String status;
  final String orderType;
  final double totalAmount;
  final double? actualAmount;
  final String? tableId;
  final String? tableCode;
  final String? tableCategory;
  final String? remark;
  final List<OrderLineItem> items;
  final String? createdAt;

  /// 堂食展示：大厅-1；外带：外带
  String get locationLabel {
    if (orderType != 'dine_in') return '外带';
    final code = tableCode?.trim() ?? '';
    final cat = tableCategory?.trim() ?? '';
    if (cat.isNotEmpty && code.isNotEmpty) return '$cat-$code';
    if (code.isNotEmpty) return code;
    if (cat.isNotEmpty) return cat;
    return '堂食';
  }

  /// 列表/详情展示用，如 6/3 18:42
  String? get createdAtLabel {
    final raw = createdAt;
    if (raw == null || raw.isEmpty) return null;
    try {
      final dt = DateTime.parse(raw).toLocal();
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return '${dt.month}/${dt.day} $h:$m';
    } catch (_) {
      return null;
    }
  }

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final itemsRaw = json['items'];
    return OrderModel(
      id: '${json['id']}',
      orderNo: '${json['order_no'] ?? ''}',
      status: '${json['status'] ?? ''}'.toLowerCase(),
      orderType: '${json['order_type'] ?? ''}',
      totalAmount: Money.apiAmountToYuan((json['total_amount'] as num?) ?? 0),
      actualAmount: json['actual_amount'] == null
          ? null
          : Money.apiAmountToYuan(json['actual_amount'] as num),
      tableId: json['table_id'] != null ? '${json['table_id']}' : null,
      tableCode: json['table_code'] as String?,
      tableCategory: json['table_category'] as String?,
      remark: json['remark'] as String?,
      items: itemsRaw is List
          ? itemsRaw
                .map((e) => OrderLineItem.fromJson(e as Map<String, dynamic>))
                .toList()
          : [],
      createdAt: json['created_at'] as String?,
    );
  }
}

class CartItem {
  CartItem({
    required this.menuId,
    required this.name,
    required this.unitPrice,
    required this.quantity,
    this.specInfo,
    this.image,
  });

  final String menuId;
  final String name;
  final double unitPrice;
  final int quantity;
  final String? specInfo;
  final String? image;

  String get cartKey => '$menuId|${specInfo ?? ''}';

  double get lineTotal => unitPrice * quantity;

  CartItem copyWith({int? quantity}) {
    return CartItem(
      menuId: menuId,
      name: name,
      unitPrice: unitPrice,
      quantity: quantity ?? this.quantity,
      specInfo: specInfo,
      image: image,
    );
  }
}
