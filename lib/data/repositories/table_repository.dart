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
    final tables = list
        .map((e) => TableItem.fromJson(e as Map<String, dynamic>))
        .toList();
    tables.sort((a, b) {
      final cmp = a.sort.compareTo(b.sort);
      if (cmp != 0) return cmp;
      return a.code.compareTo(b.code);
    });
    return tables;
  }

  Future<List<TableCategoryItem>> listTableCategories() async {
    final data = await _client.get(
      '/table/categories',
      query: {'current': 1, 'pageSize': 100},
    );
    final list = data['categories'];
    if (list is! List) return [];
    final categories = list
        .map((e) => TableCategoryItem.fromJson(e as Map<String, dynamic>))
        .toList();
    categories.sort((a, b) {
      final cmp = a.sort.compareTo(b.sort);
      if (cmp != 0) return cmp;
      return a.id.compareTo(b.id);
    });
    return categories;
  }
}
