import '../../../core/network/api_client.dart';
import '../domain/product.dart';
import '../domain/product_repository.dart';

class ApiProductRepository implements ProductRepository {
  const ApiProductRepository(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<List<Product>> getProducts({String? search, String? category}) async {
    final queryParameters = <String, dynamic>{};

    if (search != null && search.trim().isNotEmpty) {
      queryParameters['search'] = search.trim();
    }

    if (category != null && category.trim().isNotEmpty && category != 'All') {
      queryParameters['category'] = category.trim();
    }

    final json = await _apiClient.get(
      '/api/products',
      queryParameters: queryParameters,
    );

    final productsJson = json['products'] as List<dynamic>;

    return productsJson.map((item) {
      return Product.fromJson(item as Map<String, dynamic>);
    }).toList();
  }

  @override
  Future<Product> getProductById(int id) async {
    final json = await _apiClient.get('/api/products/$id');

    return Product.fromJson(json['product'] as Map<String, dynamic>);
  }
}
