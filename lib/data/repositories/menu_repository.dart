import '../models/models.dart';
import '../../core/network/api_client.dart';

class MenuRepository {
  MenuRepository(this._client);

  final ApiClient _client;

  Future<List<MenuCategory>> listCategories() async {
    final data = await _client.get(
      '/menu/categories',
      query: {'current': 1, 'pageSize': 100},
    );
    final list = data['categories'];
    if (list is! List) return [];
    return list
        .map((e) => MenuCategory.fromJson(e as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.sort.compareTo(b.sort));
  }

  Future<List<MenuItem>> listMenus({String? categoryName}) async {
    final query = <String, dynamic>{'current': 1, 'pageSize': 500};
    if (categoryName != null && categoryName.isNotEmpty && categoryName != 'all') {
      query['category'] = categoryName;
    }
    final data = await _client.get('/menus', query: query);
    final list = data['menus'];
    if (list is! List) return [];
    return list
        .map((e) => MenuItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
