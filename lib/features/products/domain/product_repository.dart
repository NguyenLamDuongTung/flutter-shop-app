import 'product.dart';

abstract interface class ProductRepository {
  Future<List<Product>> getProducts({String? search, String? category});

  Future<Product> getProductById(int id);
}
