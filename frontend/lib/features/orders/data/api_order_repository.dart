import '../../../core/network/api_client.dart';

class ApiOrderRepository {
  const ApiOrderRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<Map<String, dynamic>> createOrder({
    required String customerName,
    required String phone,
    required String address,
    required Map<int, int> items,
  }) {
    return _apiClient.post('/api/orders', {
      'customerName': customerName.trim(),
      'phone': phone.trim(),
      'address': address.trim(),
      'items': items.entries.map((entry) {
        return {'productId': entry.key, 'quantity': entry.value};
      }).toList(),
    });
  }

  Future<List<Map<String, dynamic>>> getOrders() async {
    final json = await _apiClient.get('/api/orders');

    final orders = json['orders'] as List<dynamic>? ?? [];

    return orders.map((order) {
      return Map<String, dynamic>.from(order as Map);
    }).toList();
  }
}
