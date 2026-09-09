import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../auth/presentation/login_page.dart';
import '../../orders/presentation/checkout_page.dart';
import '../../products/domain/product.dart';
import 'widgets/hero_section.dart';
import 'widgets/product_card.dart';
import 'widgets/store_header.dart';

const List<String> productCategories = [
  'Tất cả',
  'Điện thoại',
  'Laptop',
  'Đồng hồ',
  'Âm thanh',
];

class ShopHomePage extends ConsumerStatefulWidget {
  const ShopHomePage({super.key});

  @override
  ConsumerState<ShopHomePage> createState() {
    return _ShopHomePageState();
  }
}

class _ShopHomePageState extends ConsumerState<ShopHomePage> {
  final ScrollController _scrollController = ScrollController();

  final TextEditingController _searchController = TextEditingController();

  final GlobalKey _productsSectionKey = GlobalKey();

  Timer? _searchDebounce;

  String _selectedCategory = 'Tất cả';

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _scrollController.dispose();
    _searchController.dispose();

    super.dispose();
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
    );
  }

  void _scrollToProducts() {
    final productContext = _productsSectionKey.currentContext;

    if (productContext != null) {
      Scrollable.ensureVisible(
        productContext,
        duration: const Duration(milliseconds: 550),
        curve: Curves.easeOutCubic,
        alignment: 0.05,
      );
      return;
    }

    _scrollController.animateTo(
      600,
      duration: const Duration(milliseconds: 550),
      curve: Curves.easeOutCubic,
    );
  }

  void _loadProducts() {
    ref
        .read(productsControllerProvider.notifier)
        .load(
          search: _searchController.text.trim(),
          category: _selectedCategory == 'Tất cả' ? null : _selectedCategory,
        );
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();

    _searchDebounce = Timer(const Duration(milliseconds: 400), _loadProducts);
  }

  void _selectCategory(String category) {
    if (!productCategories.contains(category)) {
      return;
    }

    setState(() {
      _selectedCategory = category;
    });

    _loadProducts();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToProducts();
    });
  }

  void _showProductDetail(Product product) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return ProductDetailSheet(product: product);
      },
    );
  }

  void _showCart() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return const CartPreviewSheet();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: Column(
        children: [
          const _LocationNotice(),

          StoreHeader(
            onHomePressed: _scrollToTop,
            onProductsPressed: _scrollToProducts,
            onCategorySelected: _selectCategory,
            onCartPressed: _showCart,
          ),

          Expanded(
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                SliverToBoxAdapter(
                  child: HeroSection(onShopPressed: _scrollToProducts),
                ),

                const SliverToBoxAdapter(child: _PromotionNotice()),

                SliverToBoxAdapter(
                  child: _CategorySection(
                    selectedCategory: _selectedCategory,
                    onSelected: _selectCategory,
                  ),
                ),

                SliverToBoxAdapter(
                  key: _productsSectionKey,
                  child: _ProductHeader(
                    searchController: _searchController,
                    onSearchChanged: _onSearchChanged,
                  ),
                ),

                _buildProductContent(),

                const SliverToBoxAdapter(child: _SupportSection()),

                const SliverToBoxAdapter(child: _StoreFooter()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductContent() {
    final productsState = ref.watch(productsControllerProvider);

    return productsState.when(
      loading: () {
        return const SliverToBoxAdapter(
          child: SizedBox(
            height: 330,
            child: Center(
              child: CircularProgressIndicator(key: Key('products-loading')),
            ),
          ),
        );
      },
      error: (error, stackTrace) {
        return SliverToBoxAdapter(
          child: _StateMessage(
            icon: Icons.cloud_off_outlined,
            title: 'Không thể tải sản phẩm',
            message: error.toString(),
            buttonLabel: 'Thử lại',
            onPressed: _loadProducts,
          ),
        );
      },
      data: (products) {
        if (products.isEmpty) {
          return const SliverToBoxAdapter(
            child: _StateMessage(
              icon: Icons.search_off,
              title: 'Không tìm thấy sản phẩm',
              message: 'Hãy thử từ khóa hoặc danh mục khác.',
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 70),
          sliver: SliverLayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.crossAxisExtent;

              final crossAxisCount = switch (width) {
                >= 1180 => 4,
                >= 820 => 3,
                >= 520 => 2,
                _ => 1,
              };

              return SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: 18,
                  crossAxisSpacing: 18,
                  childAspectRatio: crossAxisCount == 1 ? 1.05 : 0.67,
                ),
                delegate: SliverChildBuilderDelegate((context, index) {
                  final product = products[index];

                  return ProductCard(
                    product: product,
                    onViewDetail: () {
                      _showProductDetail(product);
                    },
                  );
                }, childCount: products.length),
              );
            },
          ),
        );
      },
    );
  }
}

class _LocationNotice extends StatefulWidget {
  const _LocationNotice();

  @override
  State<_LocationNotice> createState() {
    return _LocationNoticeState();
  }
}

class _LocationNoticeState extends State<_LocationNotice> {
  bool _visible = true;

  @override
  Widget build(BuildContext context) {
    if (!_visible) {
      return const SizedBox.shrink();
    }

    final isDesktop = MediaQuery.sizeOf(context).width >= 700;

    return Container(
      color: const Color(0xFFF5F5F7),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120),
          child: Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 18),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Bạn đang xem cửa hàng TechZone '
                  'dành cho thị trường Việt Nam.',
                  style: TextStyle(fontSize: 13),
                ),
              ),
              if (isDesktop)
                const Text(
                  'Việt Nam',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              IconButton(
                tooltip: 'Đóng',
                onPressed: () {
                  setState(() {
                    _visible = false;
                  });
                },
                icon: const Icon(Icons.close, size: 19),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PromotionNotice extends StatelessWidget {
  const _PromotionNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 17),
      child: const Text(
        'Miễn phí giao hàng cho đơn từ 5.000.000₫. '
        'Thu cũ đổi mới và hỗ trợ trả góp.',
        textAlign: TextAlign.center,
        style: TextStyle(color: Color(0xFF1D1D1F), fontSize: 14),
      ),
    );
  }
}

class _CategorySection extends StatelessWidget {
  const _CategorySection({
    required this.selectedCategory,
    required this.onSelected,
  });

  final String selectedCategory;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    const categories = [
      (label: 'Điện thoại', icon: Icons.smartphone),
      (label: 'Laptop', icon: Icons.laptop_mac),
      (label: 'Đồng hồ', icon: Icons.watch_outlined),
      (label: 'Âm thanh', icon: Icons.headphones),
    ];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 34),
      child: Center(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: categories.map((category) {
              final selected = selectedCategory == category.label;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: InkWell(
                  key: Key('category-${category.label}'),
                  borderRadius: BorderRadius.circular(60),
                  onTap: () {
                    onSelected(category.label);
                  },
                  child: SizedBox(
                    width: 100,
                    child: Column(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            color: selected
                                ? const Color(0xFF0071E3)
                                : const Color(0xFFF5F5F7),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            category.icon,
                            color: selected ? Colors.white : Colors.black,
                            size: 32,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          category.label,
                          style: TextStyle(
                            color: selected
                                ? const Color(0xFF0071E3)
                                : Colors.black,
                            fontSize: 13,
                            fontWeight: selected
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _ProductHeader extends StatelessWidget {
  const _ProductHeader({
    required this.searchController,
    required this.onSearchChanged,
  });

  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1240),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 65, 20, 26),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final desktop = constraints.maxWidth >= 700;

              final title = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sản phẩm nổi bật.',
                    style: TextStyle(
                      color: const Color(0xFF1D1D1F),
                      fontSize: desktop ? 38 : 30,
                      height: 1.1,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Chọn thiết bị phù hợp với bạn.',
                    style: TextStyle(color: Color(0xFF6E6E73), fontSize: 17),
                  ),
                ],
              );

              final search = SizedBox(
                width: desktop ? 380 : double.infinity,
                child: TextField(
                  key: const Key('product-search-field'),
                  controller: searchController,
                  onChanged: onSearchChanged,
                  decoration: const InputDecoration(
                    hintText: 'Tìm iPhone, Samsung, MacBook...',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
              );

              if (desktop) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(child: title),
                    search,
                  ],
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [title, const SizedBox(height: 22), search],
              );
            },
          ),
        ),
      ),
    );
  }
}

class ProductDetailSheet extends ConsumerWidget {
  const ProductDetailSheet({super.key, required this.product});

  final Product product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final height = MediaQuery.sizeOf(context).height * 0.90;

    return Container(
      height: height,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          Align(
            alignment: Alignment.topRight,
            child: IconButton(
              tooltip: 'Đóng',
              onPressed: () {
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.close),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 35),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 980),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final desktop = constraints.maxWidth >= 700;

                      final image = ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: Container(
                            color: const Color(0xFFF5F5F7),
                            child: Hero(
                              tag: 'product-image-${product.id}',
                              child: Image.network(
                                product.imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(Icons.devices, size: 110);
                                },
                              ),
                            ),
                          ),
                        ),
                      );

                      final information = Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.category.toUpperCase(),
                              style: const TextStyle(
                                color: Color(0xFFBF4800),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              product.name,
                              style: const TextStyle(
                                color: Color(0xFF1D1D1F),
                                fontSize: 34,
                                height: 1.1,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 18),
                            Text(
                              product.description,
                              style: const TextStyle(
                                color: Color(0xFF6E6E73),
                                fontSize: 17,
                                height: 1.55,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              productCurrency.format(product.price),
                              style: const TextStyle(
                                fontSize: 27,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              product.isAvailable
                                  ? 'Còn ${product.stock} sản phẩm'
                                  : 'Tạm hết hàng',
                            ),
                            const SizedBox(height: 25),
                            FilledButton(
                              onPressed: product.isAvailable
                                  ? () {
                                      ref
                                          .read(cartControllerProvider.notifier)
                                          .add(product);

                                      Navigator.of(context).pop();
                                    }
                                  : null,
                              child: const Text('Thêm vào giỏ hàng'),
                            ),
                          ],
                        ),
                      );

                      if (desktop) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: image),
                            Expanded(child: information),
                          ],
                        );
                      }

                      return Column(children: [image, information]);
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CartPreviewSheet extends ConsumerWidget {
  const CartPreviewSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartControllerProvider);
    final total = ref.watch(cartTotalProvider);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.88,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 14, 10, 10),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Giỏ hàng',
                    style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          if (cart.isEmpty)
            const Expanded(
              child: _StateMessage(
                icon: Icons.shopping_bag_outlined,
                title: 'Giỏ hàng đang trống',
                message: 'Hãy thêm sản phẩm bạn yêu thích.',
              ),
            )
          else ...[
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(18),
                itemCount: cart.length,
                separatorBuilder: (_, _) {
                  return const Divider();
                },
                itemBuilder: (context, index) {
                  final line = cart.values.elementAt(index);

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        line.product.imageUrl,
                        width: 65,
                        height: 65,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const SizedBox(
                            width: 65,
                            height: 65,
                            child: Icon(Icons.devices),
                          );
                        },
                      ),
                    ),
                    title: Text(
                      line.product.name,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      '${productCurrency.format(line.product.price)}'
                      ' × ${line.quantity}',
                    ),
                    trailing: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        IconButton(
                          tooltip: 'Giảm',
                          onPressed: () {
                            ref
                                .read(cartControllerProvider.notifier)
                                .decrease(line.product);
                          },
                          icon: const Icon(Icons.remove_circle_outline),
                        ),
                        Text(
                          '${line.quantity}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          tooltip: 'Tăng',
                          onPressed: () {
                            ref
                                .read(cartControllerProvider.notifier)
                                .add(line.product);
                          },
                          icon: const Icon(Icons.add_circle_outline),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Tổng thanh toán',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        productCurrency.format(total),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 17),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      key: const Key('checkout-button'),
                      onPressed: () async {
                        final navigator = Navigator.of(context);

                        // Kiểm tra người dùng đã đăng nhập hay chưa.
                        var currentUser = ref
                            .read(authControllerProvider)
                            .value;

                        if (currentUser == null) {
                          // Đóng cửa sổ giỏ hàng trước.
                          navigator.pop();

                          // Mở trang đăng nhập.
                          final loginSuccessful = await Navigator.of(context)
                              .push<bool>(
                                MaterialPageRoute<bool>(
                                  builder: (_) => const LoginPage(),
                                ),
                              );

                          if (!context.mounted || loginSuccessful != true) {
                            return;
                          }

                          currentUser = ref.read(authControllerProvider).value;

                          if (currentUser == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Vui lòng đăng nhập để thanh toán.',
                                ),
                              ),
                            );
                            return;
                          }

                          await Navigator.of(context).push<void>(
                            MaterialPageRoute<void>(
                              builder: (_) => const CheckoutPage(),
                            ),
                          );

                          return;
                        }

                        // Đã đăng nhập: đóng giỏ hàng và chuyển đến checkout.
                        navigator.pushReplacement(
                          MaterialPageRoute<void>(
                            builder: (_) => const CheckoutPage(),
                          ),
                        );
                      },
                      child: const Text('Thanh toán'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SupportSection extends StatelessWidget {
  const _SupportSection();

  @override
  Widget build(BuildContext context) {
    const items = [
      (
        icon: Icons.local_shipping_outlined,
        title: 'Giao hàng miễn phí',
        description: 'Cho đơn hàng đủ điều kiện.',
      ),
      (
        icon: Icons.cached,
        title: 'Thu cũ đổi mới',
        description: 'Tiết kiệm khi nâng cấp.',
      ),
      (
        icon: Icons.account_balance_wallet_outlined,
        title: 'Trả góp linh hoạt',
        description: 'Nhiều phương thức thanh toán.',
      ),
      (
        icon: Icons.support_agent,
        title: 'Hỗ trợ tận tâm',
        description: 'Tư vấn trước và sau khi mua.',
      ),
    ];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 50),
      child: Center(
        child: Wrap(
          spacing: 25,
          runSpacing: 35,
          alignment: WrapAlignment.center,
          children: items.map((item) {
            return SizedBox(
              width: 245,
              child: Column(
                children: [
                  Icon(item.icon, size: 38, color: const Color(0xFF1D1D1F)),
                  const SizedBox(height: 13),
                  Text(
                    item.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.description,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Color(0xFF6E6E73)),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _StoreFooter extends StatelessWidget {
  const _StoreFooter();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF5F5F7),
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 35),
      child: const Center(
        child: Column(
          children: [
            Text(
              'TECHZONE',
              style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1),
            ),
            SizedBox(height: 10),
            Text(
              'Thiết bị công nghệ chính hãng',
              style: TextStyle(color: Color(0xFF6E6E73)),
            ),
            SizedBox(height: 18),
            Divider(),
            SizedBox(height: 12),
            Text(
              '© 2026 TechZone Store. '
              'Dự án Flutter UI Automation Testing.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF6E6E73), fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _StateMessage extends StatelessWidget {
  const _StateMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.buttonLabel,
    this.onPressed,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? buttonLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(55),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 60, color: const Color(0xFF86868B)),
            const SizedBox(height: 15),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF6E6E73)),
            ),
            if (buttonLabel != null && onPressed != null) ...[
              const SizedBox(height: 18),
              FilledButton(onPressed: onPressed, child: Text(buttonLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
