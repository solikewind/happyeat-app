class DailySalesPoint {
  const DailySalesPoint({
    required this.key,
    required this.label,
    required this.orderCount,
    required this.revenue,
    required this.receivable,
    required this.actualRevenue,
    required this.itemCount,
  });

  final String key;
  final String label;
  final int orderCount;

  /// 实收（与 revenue 一致，兼容旧字段）
  final double revenue;

  /// 应收合计
  final double receivable;

  /// 实收合计
  final double actualRevenue;
  final int itemCount;

  double get collectionGap =>
      receivable > actualRevenue ? receivable - actualRevenue : 0;

  double get collectionRate =>
      receivable <= 0 ? 1 : (actualRevenue / receivable).clamp(0.0, 1.0);
}

class MenuSalesRow {
  const MenuSalesRow({
    this.menuId,
    required this.menuName,
    this.specInfo,
    required this.quantity,
    required this.amount,
  });

  final String? menuId;
  final String menuName;
  final String? specInfo;
  final int quantity;
  final double amount;

  String get displaySpec {
    final spec = specInfo?.trim();
    if (spec == null || spec.isEmpty) return '';
    return spec;
  }

  String get groupKey {
    final id = menuId?.trim();
    if (id != null && id.isNotEmpty) return 'id:$id';
    return 'name:$menuName';
  }
}

class MenuSalesGroup {
  const MenuSalesGroup({
    required this.key,
    required this.menuName,
    required this.variants,
  });

  final String key;
  final String menuName;
  final List<MenuSalesRow> variants;

  int get quantity => variants.fold<int>(0, (sum, row) => sum + row.quantity);

  double get amount => variants.fold<double>(0, (sum, row) => sum + row.amount);

  bool get canExpand =>
      variants.length > 1 || variants.any((row) => row.displaySpec.isNotEmpty);
}

List<MenuSalesGroup> groupMenuSalesRows(List<MenuSalesRow> rows) {
  if (rows.isEmpty) return const [];

  final grouped = <String, List<MenuSalesRow>>{};
  for (final row in rows) {
    grouped.putIfAbsent(row.groupKey, () => []).add(row);
  }

  final groups = grouped.entries
      .map(
        (entry) => MenuSalesGroup(
          key: entry.key,
          menuName: entry.value.first.menuName,
          variants: List<MenuSalesRow>.from(entry.value),
        ),
      )
      .toList();

  groups.sort((a, b) {
    final qtyDiff = b.quantity.compareTo(a.quantity);
    if (qtyDiff != 0) return qtyDiff;
    return b.amount.compareTo(a.amount);
  });
  return groups;
}

class SalesOverview {
  const SalesOverview({
    required this.dailyPoints,
    required this.today,
    required this.totalRevenue,
    required this.totalReceivable,
    required this.totalActualRevenue,
    required this.totalOrders,
    required this.totalItems,
    required this.menuBreakdown,
  });

  final List<DailySalesPoint> dailyPoints;
  final DailySalesPoint today;
  final double totalRevenue;
  final double totalReceivable;
  final double totalActualRevenue;
  final int totalOrders;
  final int totalItems;
  final List<MenuSalesRow> menuBreakdown;

  double get collectionGap => totalReceivable > totalActualRevenue
      ? totalReceivable - totalActualRevenue
      : 0;

  double get collectionRate => totalReceivable <= 0
      ? 1
      : (totalActualRevenue / totalReceivable).clamp(0.0, 1.0);
}

abstract final class SalesStats {
  SalesStats._();

  static SalesOverview fromApi(
    Map<String, dynamic> overviewJson,
    Map<String, dynamic> menusJson,
  ) {
    final dailyRaw = overviewJson['daily'];
    final dailyPoints = dailyRaw is List
        ? dailyRaw
              .whereType<Map>()
              .map((e) => _dailyPointFromJson(Map<String, dynamic>.from(e)))
              .toList()
        : <DailySalesPoint>[];

    final summary = overviewJson['summary'];
    final summaryMap = summary is Map
        ? Map<String, dynamic>.from(summary)
        : <String, dynamic>{};

    final today = dailyPoints.isNotEmpty
        ? dailyPoints.last
        : _dailyPointFromJson({
            'date': _todayKey(),
            'order_count': summaryMap['order_count'] ?? 0,
            'revenue': summaryMap['revenue'] ?? 0,
            'receivable':
                summaryMap['receivable'] ?? summaryMap['revenue'] ?? 0,
            'actual_revenue':
                summaryMap['actual_revenue'] ?? summaryMap['revenue'] ?? 0,
            'item_count': summaryMap['item_count'] ?? 0,
          });

    final rowsRaw = menusJson['rows'];
    final menuBreakdown = rowsRaw is List
        ? rowsRaw
              .whereType<Map>()
              .map((e) => _menuRowFromJson(Map<String, dynamic>.from(e)))
              .toList()
        : <MenuSalesRow>[];

    final totalActual = _amountToYuan(
      summaryMap['actual_revenue'] ?? summaryMap['revenue'],
    );
    final totalReceivable = _amountToYuan(
      summaryMap['receivable'] ?? summaryMap['revenue'],
    );

    return SalesOverview(
      dailyPoints: dailyPoints,
      today: today,
      totalRevenue: totalActual,
      totalReceivable: totalReceivable,
      totalActualRevenue: totalActual,
      totalOrders:
          (summaryMap['order_count'] as num?)?.toInt() ?? today.orderCount,
      totalItems:
          (summaryMap['item_count'] as num?)?.toInt() ?? today.itemCount,
      menuBreakdown: menuBreakdown,
    );
  }

  static DailySalesPoint _dailyPointFromJson(Map<String, dynamic> json) {
    final date = (json['date'] as String?) ?? _todayKey();
    final dt = DateTime.tryParse(date);
    final actual = _amountToYuan(json['actual_revenue'] ?? json['revenue']);
    final receivable = _amountToYuan(json['receivable'] ?? json['revenue']);
    return DailySalesPoint(
      key: date,
      label: dt == null ? date : '${dt.month}月${dt.day}日',
      orderCount: (json['order_count'] as num?)?.toInt() ?? 0,
      revenue: actual,
      receivable: receivable,
      actualRevenue: actual,
      itemCount: (json['item_count'] as num?)?.toInt() ?? 0,
    );
  }

  static MenuSalesRow _menuRowFromJson(Map<String, dynamic> json) {
    final spec = (json['spec_info'] as String?)?.trim();
    final menuIdRaw = json['menu_id'];
    final menuId = menuIdRaw == null || '$menuIdRaw'.trim().isEmpty
        ? null
        : '$menuIdRaw'.trim();
    return MenuSalesRow(
      menuId: menuId,
      menuName: (json['menu_name'] as String?) ?? '',
      specInfo: spec == null || spec.isEmpty ? null : spec,
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      amount: _amountToYuan(json['amount']),
    );
  }

  static double _amountToYuan(dynamic raw) {
    if (raw == null) return 0;
    if (raw is num) return raw.toDouble();
    return double.tryParse(raw.toString()) ?? 0;
  }

  static String _todayKey() {
    final now = DateTime.now();
    final y = now.year;
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
