import '../models/models.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/money.dart';

class SettlementRepository {
  SettlementRepository(this._client);

  final ApiClient _client;

  SettlementModel _parseSettlement(Map<String, dynamic> data) {
    final raw = data['settlement'];
    if (raw is Map<String, dynamic>) {
      return SettlementModel.fromJson(raw);
    }
    throw Exception('结账单响应格式异常');
  }

  Future<({List<SettlementModel> settlements, int total})> listSettlements({
    int current = 1,
    int pageSize = 20,
    String? status,
    String? customerName,
  }) async {
    final query = <String, dynamic>{'current': current, 'pageSize': pageSize};
    if (status != null && status.isNotEmpty) {
      query['status'] = status.toUpperCase();
    }
    if (customerName != null && customerName.trim().isNotEmpty) {
      query['customer_name'] = customerName.trim();
    }
    final data = await _client.get('/settlements', query: query);
    final list = data['settlements'];
    final settlements = list is List
        ? list
              .map(
                (e) => SettlementModel.fromJson(e as Map<String, dynamic>),
              )
              .toList()
        : <SettlementModel>[];
    return (settlements: settlements, total: (data['total'] as num?)?.toInt() ?? 0);
  }

  Future<SettlementModel> getSettlement(String id) async {
    final data = await _client.get('/settlement/$id');
    return _parseSettlement(data);
  }

  Future<SettlementModel> createSettlement({
    required String customerName,
    String? remark,
  }) async {
    final data = await _client.post(
      '/settlements',
      data: {
        'customer_name': customerName.trim(),
        if (remark != null && remark.trim().isNotEmpty) 'remark': remark.trim(),
      },
    );
    return _parseSettlement(data);
  }

  Future<SettlementModel> addOrder({
    required String settlementId,
    required String orderId,
  }) async {
    final data = await _client.post(
      '/settlement/$settlementId/orders',
      data: {'order_id': orderId},
    );
    return _parseSettlement(data);
  }

  Future<SettlementModel> removeOrder({
    required String settlementId,
    required String orderId,
  }) async {
    final data = await _client.delete(
      '/settlement/$settlementId/orders/$orderId',
    );
    return _parseSettlement(data);
  }

  Future<SettlementModel> settle({
    required String settlementId,
    required double actualYuan,
    String? remark,
  }) async {
    final data = await _client.post(
      '/settlement/$settlementId/settle',
      data: {
        'actual_amount': Money.yuanToApiInt(actualYuan),
        if (remark != null && remark.trim().isNotEmpty) 'remark': remark.trim(),
      },
    );
    return _parseSettlement(data);
  }

  Future<void> deleteSettlement(String id) async {
    await _client.delete('/settlement/$id');
  }
}
