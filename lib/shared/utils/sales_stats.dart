import '../../data/models/models.dart';

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

class _MenuAgg {
  _MenuAgg({required this.qty, required this.amount, this.spec});

  int qty;
  double amount;
  String? spec;
}

abstract final class SalesStats {
  SalesStats._();

  static const historyDays = 1;
  static const pageSize = 200;
  static const maxPages = 10;

  static DateTime get todayStart {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  static bool countsAsSale(String status) {
    final s = status.trim().toLowerCase();
    return s == 'completed' || s == 'paid' || s == 'preparing';
  }

  static DateTime? _parseCreatedAt(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      return DateTime.parse(raw).toLocal();
    } catch (_) {
      return null;
    }
  }

  static String _dayKey(DateTime dt) {
    final y = dt.year;
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static String _dayLabel(DateTime dt) {
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$m/$d';
  }

  static List<DailySalesPoint> _seedDailyPoints() {
    final start = DateTime.now();
    final anchor = DateTime(start.year, start.month, start.day);
    final first = anchor.subtract(const Duration(days: historyDays - 1));
    return List.generate(historyDays, (index) {
      final day = first.add(Duration(days: index));
      return DailySalesPoint(
        key: _dayKey(day),
        label: _dayLabel(day),
        orderCount: 0,
        revenue: 0,
        itemCount: 0,
      );
    });
  }

  static SalesOverview fromOrders(List<OrderModel> orders) {
    final seed = _seedDailyPoints();
    final dayIndex = {for (var i = 0; i < seed.length; i++) seed[i].key: i};
    final firstKey = seed.first.key;
    final counts = List<int>.filled(seed.length, 0);
    final revenues = List<double>.filled(seed.length, 0);
    final itemCounts = List<int>.filled(seed.length, 0);

    final menuMap = <String, _MenuAgg>{};
    var totalRevenue = 0.0;
    var totalOrders = 0;
    var totalItems = 0;

    for (final order in orders) {
      if (!countsAsSale(order.status)) continue;
      final created = _parseCreatedAt(order.createdAt);
      if (created == null || created.isBefore(todayStart)) continue;

      final key = _dayKey(created);
      final revenue = order.actualAmount ?? order.totalAmount;
      totalRevenue += revenue;
      totalOrders += 1;

      var orderItems = 0;
      for (final item in order.items) {
        orderItems += item.quantity;
        totalItems += item.quantity;

        final spec = item.specInfo?.trim();
        final rowKey = spec == null || spec.isEmpty
            ? item.menuName
            : '${item.menuName}|$spec';
        final prev = menuMap[rowKey];
        final lineAmount = item.amount > 0
            ? item.amount
            : item.unitPrice * item.quantity;
        if (prev == null) {
          menuMap[rowKey] = _MenuAgg(
            qty: item.quantity,
            amount: lineAmount,
            spec: spec,
          );
        } else {
          prev.qty += item.quantity;
          prev.amount += lineAmount;
        }
      }

      final idx = dayIndex[key];
      if (idx != null && key.compareTo(firstKey) >= 0) {
        counts[idx] += 1;
        revenues[idx] += revenue;
        itemCounts[idx] += orderItems;
      }
    }

    final dailyPoints = List<DailySalesPoint>.generate(seed.length, (i) {
      return DailySalesPoint(
        key: seed[i].key,
        label: seed[i].label,
        orderCount: counts[i],
        revenue: revenues[i],
        itemCount: itemCounts[i],
      );
    });

    final menuBreakdown = menuMap.entries
        .map((entry) {
          final parts = entry.key.split('|');
          return MenuSalesRow(
            menuName: parts.first,
            specInfo: entry.value.spec,
            quantity: entry.value.qty,
            amount: entry.value.amount,
          );
        })
        .toList()
      ..sort((a, b) {
        final byQty = b.quantity.compareTo(a.quantity);
        if (byQty != 0) return byQty;
        return b.amount.compareTo(a.amount);
      });

    return SalesOverview(
      dailyPoints: dailyPoints,
      today: dailyPoints.last,
      totalRevenue: totalRevenue,
      totalOrders: totalOrders,
      totalItems: totalItems,
      menuBreakdown: menuBreakdown,
    );
  }
}
