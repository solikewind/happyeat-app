import '../../core/network/api_client.dart';
import '../../shared/utils/sales_stats.dart';

class StatsRepository {
  StatsRepository(this._client);

  final ApiClient _client;

  /// 加载经营统计；[startDate]/[endDate] 格式 YYYY-MM-DD，均可缺省为今天。
  Future<SalesOverview> loadSalesOverview({
    String? startDate,
    String? endDate,
  }) async {
    final hasRange =
        (startDate != null && startDate.isNotEmpty) ||
        (endDate != null && endDate.isNotEmpty);
    final query = <String, dynamic>{};
    if (startDate != null && startDate.isNotEmpty) {
      query['start_date'] = startDate;
    }
    if (endDate != null && endDate.isNotEmpty) {
      query['end_date'] = endDate;
    }

    final overview = hasRange
        ? await _client.get('/stats/daily', query: query)
        : await _client.get('/stats/daily/overview');

    final menus = hasRange
        ? await _client.get('/stats/menus', query: query)
        : await _client.get('/stats/menus');

    return SalesStats.fromApi(overview, menus);
  }
}
