import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/api_client.dart';
import '../features/auth/data/api_auth_repository.dart';
import '../features/auth/data/auth_storage.dart';
import '../features/auth/domain/app_user.dart';
import '../features/auth/domain/auth_repository.dart';
import '../features/orders/data/api_order_repository.dart';
import '../features/products/data/api_product_repository.dart';
import '../features/products/domain/product.dart';
import '../features/products/domain/product_repository.dart';

/// ============================================================
/// API CLIENT
/// ============================================================

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

/// ============================================================
/// AUTHENTICATION
/// ============================================================

final authStorageProvider = Provider<AuthStorage>((ref) {
  return AuthStorage();
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final authStorage = ref.watch(authStorageProvider);

  return ApiAuthRepository(apiClient, authStorage);
});

class AuthController extends AsyncNotifier<AppUser?> {
  @override
  Future<AppUser?> build() async {
    try {
      final repository = ref.read(authRepositoryProvider);

      // Đọc lại token và user đã lưu trong trình duyệt.
      final session = await repository.restoreSession();

      if (session == null) {
        return null;
      }

      // Gắn lại token vào ApiClient cho các API cần đăng nhập.
      ref.read(apiClientProvider).token = session.token;

      return session.user;
    } catch (_) {
      // Nếu session cũ bị lỗi thì xóa session để tránh app bị treo.
      await ref.read(authRepositoryProvider).logout();

      return null;
    }
  }

  Future<bool> login(String email, String password) async {
    if (state.isLoading) {
      return false;
    }

    state = const AsyncLoading();

    try {
      final repository = ref.read(authRepositoryProvider);

      final session = await repository.login(email.trim(), password);

      // ApiAuthRepository sẽ lưu session.
      // Đặt lại token ở đây để đảm bảo API sau đăng nhập hoạt động.
      ref.read(apiClientProvider).token = session.token;

      state = AsyncData(session.user);

      return true;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);

      return false;
    }
  }

  Future<void> logout() async {
    if (state.isLoading) {
      return;
    }

    final previousUser = state.value;

    state = const AsyncLoading();

    try {
      await ref.read(authRepositoryProvider).logout();

      ref.read(apiClientProvider).token = null;

      state = const AsyncData(null);
    } catch (error, stackTrace) {
      // Nếu logout gặp lỗi, khôi phục user để giao diện không bị sai trạng thái.
      if (previousUser != null) {
        state = AsyncData(previousUser);
        return;
      }

      state = AsyncError(error, stackTrace);
    }
  }
}

final authControllerProvider = AsyncNotifierProvider<AuthController, AppUser?>(
  AuthController.new,
);

/// Trả về user hiện tại.
///
/// Sử dụng:
/// final user = ref.watch(currentUserProvider);
final currentUserProvider = Provider<AppUser?>((ref) {
  return ref.watch(authControllerProvider).value;
});

/// Trả về true khi đã đăng nhập.
///
/// Sử dụng:
/// final isLoggedIn = ref.watch(isLoggedInProvider);
final isLoggedInProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider) != null;
});

/// ============================================================
/// PRODUCTS
/// ============================================================

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);

  return ApiProductRepository(apiClient);
});

class ProductsController extends AsyncNotifier<List<Product>> {
  @override
  Future<List<Product>> build() async {
    return ref.read(productRepositoryProvider).getProducts();
  }

  Future<void> load({String? search, String? category}) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      return ref
          .read(productRepositoryProvider)
          .getProducts(search: search, category: category);
    });
  }

  Future<void> refreshProducts() async {
    await load();
  }
}

final productsControllerProvider =
    AsyncNotifierProvider<ProductsController, List<Product>>(
      ProductsController.new,
    );

/// ============================================================
/// CART
/// ============================================================

class CartLine {
  const CartLine({required this.product, required this.quantity});

  final Product product;
  final int quantity;

  double get total {
    return product.price * quantity;
  }

  CartLine copyWith({Product? product, int? quantity}) {
    return CartLine(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
    );
  }
}

class CartController extends Notifier<Map<int, CartLine>> {
  @override
  Map<int, CartLine> build() {
    return <int, CartLine>{};
  }

  void add(Product product) {
    if (!product.isAvailable) {
      return;
    }

    final currentLine = state[product.id];
    final currentQuantity = currentLine?.quantity ?? 0;
    final newQuantity = currentQuantity + 1;

    if (newQuantity > product.stock) {
      return;
    }

    state = <int, CartLine>{
      ...state,
      product.id: CartLine(product: product, quantity: newQuantity),
    };
  }

  void decrease(Product product) {
    final currentLine = state[product.id];

    if (currentLine == null) {
      return;
    }

    if (currentLine.quantity <= 1) {
      remove(product.id);
      return;
    }

    state = <int, CartLine>{
      ...state,
      product.id: currentLine.copyWith(quantity: currentLine.quantity - 1),
    };
  }

  void updateQuantity(Product product, int quantity) {
    if (quantity <= 0) {
      remove(product.id);
      return;
    }

    if (quantity > product.stock) {
      return;
    }

    state = <int, CartLine>{
      ...state,
      product.id: CartLine(product: product, quantity: quantity),
    };
  }

  void remove(int productId) {
    if (!state.containsKey(productId)) {
      return;
    }

    final updatedCart = Map<int, CartLine>.from(state);

    updatedCart.remove(productId);

    state = updatedCart;
  }

  void clear() {
    state = <int, CartLine>{};
  }
}

final cartControllerProvider =
    NotifierProvider<CartController, Map<int, CartLine>>(CartController.new);

final cartItemCountProvider = Provider<int>((ref) {
  final cart = ref.watch(cartControllerProvider);

  return cart.values.fold<int>(0, (total, line) => total + line.quantity);
});

final cartTotalProvider = Provider<double>((ref) {
  final cart = ref.watch(cartControllerProvider);

  return cart.values.fold<double>(0, (total, line) => total + line.total);
});

final cartIsEmptyProvider = Provider<bool>((ref) {
  return ref.watch(cartControllerProvider).isEmpty;
});

/// ============================================================
/// ORDERS
/// ============================================================

final orderRepositoryProvider = Provider<ApiOrderRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);

  return ApiOrderRepository(apiClient);
});
