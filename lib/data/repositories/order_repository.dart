import '../models/models.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/money.dart';

class OrderRepository {
  OrderRepository(this._client);

  final ApiClient _client;

  Future<({List<OrderModel> orders, int total})> listOrders({
    int current = 1,
    int pageSize = 20,
    String? status,
  }) async {
    final query = <String, dynamic>{'current': current, 'pageSize': pageSize};
    if (status != null && status.isNotEmpty) {
      query['status'] = status.toUpperCase();
    }
    final data = await _client.get('/orders', query: query);
    final list = data['orders'];
    final orders = list is List
        ? list
              .map((e) => OrderModel.fromJson(e as Map<String, dynamic>))
              .toList()
        : <OrderModel>[];
    return (orders: orders, total: (data['total'] as num?)?.toInt() ?? 0);
  }

  Future<OrderModel> getOrder(String id) async {
    final data = await _client.get('/order/$id');
    final order = data['order'];
    if (order is! Map<String, dynamic>) {
      throw Exception('订单不存在');
    }
    return OrderModel.fromJson(order);
  }

  Future<OrderModel> createOrder({
    required String orderType,
    String? tableId,
    required List<CartItem> items,
    required double totalYuan,
    double? actualYuan,
    String? remark,
  }) async {
    final data = await _client.post(
      '/orders',
      data: {
        'order_type': orderType,
        if (tableId != null) 'table_id': tableId!,
        'items': items
            .map(
              (i) => {
                'menu_name': i.name,
                'quantity': i.quantity,
                'unit_price': Money.yuanToApiAmount(i.unitPrice),
                if (i.specInfo != null) 'spec_info': i.specInfo,
              },
            )
            .toList(),
        'total_amount': Money.yuanToApiAmount(totalYuan),
        'actual_amount': Money.yuanToApiAmount(actualYuan ?? totalYuan),
        if (remark != null && remark.isNotEmpty) 'remark': remark,
      },
    );
    final order = data['order'];
    if (order is Map<String, dynamic>) {
      return OrderModel.fromJson(order);
    }
    throw Exception('下单失败');
  }

  /// 厨房小票打印（商鹏，与 Web 工作台「打印」一致）
  Future<void> printOrderKitchen(String id) async {
    await _client.post('/order/$id/print');
  }

  /// 更新订单状态（status 小写即可，会转为后端枚举大写）
  Future<void> updateOrderStatus(String id, String status) async {
    final normalized = status.trim().toLowerCase();
    await _client.put(
      '/order/$id/status',
      data: {'status': normalized.toUpperCase()},
    );
  }
}
