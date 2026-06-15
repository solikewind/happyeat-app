class DailySalesPoint {
  const DailySalesPoint({
    required this.key,
    required this.label,
    required this.orderCount,
    required this.revenue,
    required this.itemCount,
  });

  final String key;
  final String label;
  final int orderCount;
  final double revenue;
  final int itemCount;
}

class MenuSalesRow {
  const MenuSalesRow({
    required this.menuName,
    this.specInfo,
    required this.quantity,
    required this.amount,
  });

  final String menuName;
  final String? specInfo;
  final int quantity;
  final double amount;

  String get displaySpec {
    final spec = specInfo?.trim();
    if (spec == null || spec.isEmpty) return '';
    return spec;
  }
}

class SalesOverview {
  const SalesOverview({
    required this.dailyPoints,
    required this.today,
    required this.totalRevenue,
    required this.totalOrders,
    required this.totalItems,
    required this.menuBreakdown,
  });

  final List<DailySalesPoint> dailyPoints;
  final DailySalesPoint today;
  final double totalRevenue;
  final int totalOrders;
  final int totalItems;
  final List<MenuSalesRow> menuBreakdown;
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
              .map(
                (e) => _dailyPointFromJson(Map<String, dynamic>.from(e)),
              )
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
            'item_count': summaryMap['item_count'] ?? 0,
          });

    final rowsRaw = menusJson['rows'];
    final menuBreakdown = rowsRaw is List
        ? rowsRaw
              .whereType<Map>()
              .map((e) => _menuRowFromJson(Map<String, dynamic>.from(e)))
              .toList()
        : <MenuSalesRow>[];

    return SalesOverview(
      dailyPoints: dailyPoints,
      today: today,
      totalRevenue: _amountToYuan(summaryMap['revenue']),
      totalOrders: (summaryMap['order_count'] as num?)?.toInt() ?? today.orderCount,
      totalItems: (summaryMap['item_count'] as num?)?.toInt() ?? today.itemCount,
      menuBreakdown: menuBreakdown,
    );
  }

  static DailySalesPoint _dailyPointFromJson(Map<String, dynamic> json) {
    final date = (json['date'] as String?) ?? _todayKey();
    final dt = DateTime.tryParse(date);
    return DailySalesPoint(
      key: date,
      label: dt == null ? date : '${dt.month}月${dt.day}日',
      orderCount: (json['order_count'] as num?)?.toInt() ?? 0,
      revenue: _amountToYuan(json['revenue']),
      itemCount: (json['item_count'] as num?)?.toInt() ?? 0,
    );
  }

  static MenuSalesRow _menuRowFromJson(Map<String, dynamic> json) {
    final spec = (json['spec_info'] as String?)?.trim();
    return MenuSalesRow(
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
