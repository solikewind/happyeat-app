import '../models/models.dart';
import '../../core/network/api_client.dart';
import '../../shared/utils/sales_stats.dart';
import 'order_repository.dart';

class StatsRepository {
  StatsRepository(this._client);

  final ApiClient _client;

  Future<SalesOverview> loadSalesOverview() async {
    final orders = await _fetchRecentOrders();
    return SalesStats.fromOrders(orders);
  }

  Future<List<OrderModel>> _fetchRecentOrders() async {
    final repo = OrderRepository(_client);
    final first = await repo.listOrders(
      current: 1,
      pageSize: SalesStats.pageSize,
    );
    final all = <OrderModel>[...first.orders];
    final total = first.total;
    if (all.length >= total) return all;

    for (var page = 2; page <= SalesStats.maxPages; page++) {
      final res = await repo.listOrders(
        current: page,
        pageSize: SalesStats.pageSize,
      );
      if (res.orders.isEmpty) break;
      all.addAll(res.orders);

      final oldest = res.orders.last.createdAt;
      if (oldest != null) {
        final dt = DateTime.tryParse(oldest)?.toLocal();
        if (dt != null && dt.isBefore(SalesStats.todayStart)) break;
      }
      if (all.length >= total) break;
    }
    return all;
  }
}
