import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers.dart';
import '../../../auth/presentation/login_page.dart';

class StoreHeader extends ConsumerWidget {
  const StoreHeader({
    super.key,
    required this.onHomePressed,
    required this.onProductsPressed,
    required this.onCategorySelected,
    required this.onCartPressed,
  });

  final VoidCallback onHomePressed;
  final VoidCallback onProductsPressed;
  final ValueChanged<String> onCategorySelected;
  final VoidCallback onCartPressed;

  Future<void> _openLogin(BuildContext context) async {
    await Navigator.of(context)
        .push<bool>(MaterialPageRoute(builder: (_) => const LoginPage()));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isDesktop = screenWidth >= 950;

    final authState = ref.watch(authControllerProvider);
    final user = authState.value;
    final cartCount = ref.watch(cartItemCountProvider);

    return Material(
      color: Colors.white.withValues(alpha: 0.96),
      elevation: 0,
      child: Container(
        height: 54,
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFE5E5E7))),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1120),
            child: Row(
              children: [
                const SizedBox(width: 18),

                InkWell(
                  key: const Key('store-logo'),
                  borderRadius: BorderRadius.circular(30),
                  onTap: onHomePressed,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                    child: Row(
                      children: [
                        Icon(Icons.bolt_rounded, size: 25, color: Colors.black),
                        SizedBox(width: 5),
                        Text(
                          'TECHZONE',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                if (isDesktop) ...[
                  const Spacer(),

                  _NavigationButton(
                    label: 'Cửa hàng',
                    onPressed: onProductsPressed,
                  ),
                  _NavigationButton(
                    label: 'MacBook',
                    onPressed: () {
                      onCategorySelected('Laptop');
                    },
                  ),
                  _NavigationButton(
                    label: 'iPhone',
                    onPressed: () {
                      onCategorySelected('Điện thoại');
                    },
                  ),
                  _NavigationButton(
                    label: 'Samsung',
                    onPressed: () {
                      onCategorySelected('Điện thoại');
                    },
                  ),
                  _NavigationButton(
                    label: 'Watch',
                    onPressed: () {
                      onCategorySelected('Đồng hồ');
                    },
                  ),
                  _NavigationButton(
                    label: 'Âm thanh',
                    onPressed: () {
                      onCategorySelected('Âm thanh');
                    },
                  ),
                  _NavigationButton(label: 'Hỗ trợ', onPressed: () {}),

                  const Spacer(),
                ] else
                  const Spacer(),

                IconButton(
                  key: const Key('header-search-button'),
                  tooltip: 'Tìm kiếm',
                  onPressed: onProductsPressed,
                  icon: const Icon(Icons.search, size: 21, color: Colors.black),
                ),

                IconButton(
                  key: const Key('cart-button'),
                  tooltip: 'Giỏ hàng',
                  onPressed: onCartPressed,
                  icon: Badge(
                    isLabelVisible: cartCount > 0,
                    label: Text('$cartCount'),
                    child: const Icon(
                      Icons.shopping_bag_outlined,
                      size: 21,
                      color: Colors.black,
                    ),
                  ),
                ),

                if (user == null)
                  IconButton(
                    key: const Key('navbar-login-button'),
                    tooltip: 'Đăng nhập',
                    onPressed: () {
                      _openLogin(context);
                    },
                    icon: const Icon(
                      Icons.person_outline,
                      size: 22,
                      color: Colors.black,
                    ),
                  )
                else
                  PopupMenuButton<String>(
                    key: const Key('account-menu-button'),
                    tooltip: user.displayName,
                    onSelected: (value) {
                      if (value == 'logout') {
                        ref.read(authControllerProvider.notifier).logout();
                      }
                    },
                    itemBuilder: (_) {
                      return [
                        PopupMenuItem<String>(
                          enabled: false,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.displayName,
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                user.email,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        const PopupMenuDivider(),
                        const PopupMenuItem<String>(
                          value: 'logout',
                          child: Row(
                            children: [
                              Icon(Icons.logout),
                              SizedBox(width: 10),
                              Text('Đăng xuất'),
                            ],
                          ),
                        ),
                      ];
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: const Color(0xFFF0F0F2),
                        child: Text(
                          user.displayName.isNotEmpty
                              ? user.displayName[0].toUpperCase()
                              : 'U',
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),

                if (!isDesktop)
                  PopupMenuButton<String>(
                    tooltip: 'Menu',
                    icon: const Icon(Icons.menu, color: Colors.black),
                    onSelected: (value) {
                      switch (value) {
                        case 'home':
                          onHomePressed();
                          break;

                        case 'products':
                          onProductsPressed();
                          break;

                        case 'phones':
                          onCategorySelected('Điện thoại');
                          break;

                        case 'laptops':
                          onCategorySelected('Laptop');
                          break;

                        case 'watches':
                          onCategorySelected('Đồng hồ');
                          break;

                        case 'audio':
                          onCategorySelected('Âm thanh');
                          break;
                      }
                    },
                    itemBuilder: (_) {
                      return const [
                        PopupMenuItem(value: 'home', child: Text('Trang chủ')),
                        PopupMenuItem(
                          value: 'products',
                          child: Text('Tất cả sản phẩm'),
                        ),
                        PopupMenuItem(
                          value: 'phones',
                          child: Text('Điện thoại'),
                        ),
                        PopupMenuItem(value: 'laptops', child: Text('Laptop')),
                        PopupMenuItem(value: 'watches', child: Text('Đồng hồ')),
                        PopupMenuItem(value: 'audio', child: Text('Âm thanh')),
                      ];
                    },
                  ),

                const SizedBox(width: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavigationButton extends StatelessWidget {
  const _NavigationButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 18),
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
      ),
      child: Text(label),
    );
  }
}
