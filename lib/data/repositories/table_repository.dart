import '../models/models.dart';
import '../models/table_category.dart';
import '../../core/network/api_client.dart';

class TableRepository {
  TableRepository(this._client);

  final ApiClient _client;

  Future<List<TableItem>> listTables({String? status}) async {
    final query = <String, dynamic>{'current': 1, 'pageSize': 500};
    if (status != null && status.isNotEmpty) {
      query['status'] = status;
    }
    final data = await _client.get('/tables', query: query);
    final list = data['tables'];
    if (list is! List) return [];
    return list
        .map((e) => TableItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<TableCategoryItem>> listTableCategories() async {
    final data = await _client.get(
      '/table/categories',
      query: {'current': 1, 'pageSize': 100},
    );
    final list = data['categories'];
    if (list is! List) return [];
    return list
        .map((e) => TableCategoryItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
