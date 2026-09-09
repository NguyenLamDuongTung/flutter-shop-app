import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../app/providers.dart';
import '../../../products/domain/product.dart';

final NumberFormat productCurrency = NumberFormat.currency(
  locale: 'vi_VN',
  symbol: '₫',
  decimalDigits: 0,
);

class ProductCard extends ConsumerWidget {
  const ProductCard({
    super.key,
    required this.product,
    required this.onViewDetail,
  });

  final Product product;
  final VoidCallback onViewDetail;

  void _addToCart(BuildContext context, WidgetRef ref) {
    ref.read(cartControllerProvider.notifier).add(product);

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 1),
          content: Text('Đã thêm ${product.name} vào giỏ hàng'),
          action: SnackBarAction(label: 'Đóng', onPressed: () {}),
        ),
      );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      color: Colors.white,
      child: InkWell(
        key: Key('product-${product.id}'),
        onTap: onViewDetail,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                color: const Color(0xFFF5F5F7),
                child: Hero(
                  tag: 'product-image-${product.id}',
                  child: Image.network(
                    product.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Icon(
                          Icons.devices_rounded,
                          size: 72,
                          color: Color(0xFF86868B),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.category.toUpperCase(),
                    style: const TextStyle(
                      color: Color(0xFFBF4800),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 7),

                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF1D1D1F),
                      fontSize: 18,
                      height: 1.2,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Text(
                    productCurrency.format(product.price),
                    style: const TextStyle(
                      color: Color(0xFF1D1D1F),
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 14),

                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      key: Key('add-to-cart-${product.id}'),
                      onPressed: product.isAvailable
                          ? () {
                              _addToCart(context, ref);
                            }
                          : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF0071E3),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 43),
                      ),
                      child: Text(
                        product.isAvailable ? 'Thêm vào giỏ' : 'Tạm hết hàng',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
