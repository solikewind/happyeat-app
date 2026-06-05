import '../models/models.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/money.dart';

class StoredObject {
  StoredObject({
    required this.id,
    required this.url,
  });

  final String id;
  final String url;

  factory StoredObject.fromJson(Map<String, dynamic> json) {
    return StoredObject(
      id: '${json['id']}',
      url: '${json['url'] ?? ''}',
    );
  }
}

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
    if (categoryName != null &&
        categoryName.isNotEmpty &&
        categoryName != 'all') {
      query['category'] = categoryName;
    }
    final data = await _client.get('/menus', query: query);
    final list = data['menus'];
    if (list is! List) return [];
    return list
        .map((e) => MenuItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<MenuItem> getMenu(String id) async {
    final data = await _client.get('/menu/$id');
    final menu = data['menu'];
    if (menu is! Map<String, dynamic>) {
      throw Exception('菜品不存在');
    }
    return MenuItem.fromJson(menu);
  }

  Future<void> createMenu({
    required String name,
    required double priceYuan,
    required String categoryId,
    String? description,
    String? image,
    String? objectId,
  }) async {
    await _client.post(
      '/menus',
      data: {
        'name': name,
        'price': Money.yuanToApiInt(priceYuan),
        'category_id': categoryId,
        if (description != null && description.isNotEmpty)
          'description': description,
        if (objectId != null && objectId.isNotEmpty) 'object_id': objectId,
        if (image != null && image.isNotEmpty) 'image': image,
      },
    );
  }

  Future<void> updateMenu({
    required String id,
    required String name,
    required double priceYuan,
    required String categoryId,
    String? description,
    String? image,
    String? objectId,
  }) async {
    final hasObject = objectId != null && objectId.isNotEmpty;
    await _client.put(
      '/menu/$id',
      data: {
        'name': name,
        'price': Money.yuanToApiInt(priceYuan),
        'category_id': categoryId,
        if (description != null) 'description': description,
        if (hasObject) 'object_id': objectId,
        // 有 object_id 时由后端解析封面 URL，避免回传带签名的临时 image 触发校验失败
        if (!hasObject && image != null && image.isNotEmpty) 'image': image,
      },
    );
  }

  Future<void> deleteMenu(String id) async {
    await _client.delete('/menu/$id');
  }

  Future<StoredObject> uploadObject(String filePath, {String? fileName}) async {
    final data = await _client.postMultipart(
      '/objects/upload',
      fieldName: 'file',
      filePath: filePath,
      fileName: fileName,
    );
    final object = data['object'];
    if (object is! Map<String, dynamic>) {
      throw Exception('上传失败');
    }
    return StoredObject.fromJson(object);
  }
}
