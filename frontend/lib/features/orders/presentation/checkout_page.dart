import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/providers.dart';

final NumberFormat checkoutCurrency = NumberFormat.currency(
  locale: 'vi_VN',
  symbol: '₫',
  decimalDigits: 0,
);

class CheckoutPage extends ConsumerStatefulWidget {
  const CheckoutPage({super.key});

  @override
  ConsumerState<CheckoutPage> createState() {
    return _CheckoutPageState();
  }
}

class _CheckoutPageState extends ConsumerState<CheckoutPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();

  final TextEditingController _phoneController = TextEditingController();

  final TextEditingController _addressController = TextEditingController();

  bool _submitting = false;

  @override
  void initState() {
    super.initState();

    final user = ref.read(authControllerProvider).value;

    _nameController.text = user?.displayName ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();

    super.dispose();
  }

  String? _validateName(String? value) {
    final name = value?.trim() ?? '';

    if (name.isEmpty) {
      return 'Vui lòng nhập họ và tên';
    }

    if (name.length < 2) {
      return 'Họ tên phải có ít nhất 2 ký tự';
    }

    return null;
  }

  String? _validatePhone(String? value) {
    final phone = value?.trim() ?? '';

    if (phone.isEmpty) {
      return 'Vui lòng nhập số điện thoại';
    }

    final validPhone = RegExp(r'^(0|\+84)[0-9]{9,10}$');

    if (!validPhone.hasMatch(phone)) {
      return 'Số điện thoại không hợp lệ';
    }

    return null;
  }

  String? _validateAddress(String? value) {
    final address = value?.trim() ?? '';

    if (address.isEmpty) {
      return 'Vui lòng nhập địa chỉ nhận hàng';
    }

    if (address.length < 8) {
      return 'Địa chỉ phải có ít nhất 8 ký tự';
    }

    return null;
  }

  Future<void> _placeOrder() async {
    FocusScope.of(context).unfocus();

    final valid = _formKey.currentState?.validate() ?? false;

    if (!valid || _submitting) {
      return;
    }

    final cart = ref.read(cartControllerProvider);

    if (cart.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Giỏ hàng đang trống.')));

      return;
    }

    setState(() {
      _submitting = true;
    });

    try {
      final orderItems = <int, int>{
        for (final line in cart.values) line.product.id: line.quantity,
      };

      final response = await ref
          .read(orderRepositoryProvider)
          .createOrder(
            customerName: _nameController.text,
            phone: _phoneController.text,
            address: _addressController.text,
            items: orderItems,
          );

      if (!mounted) {
        return;
      }

      final order = response['order'] as Map<String, dynamic>;

      ref.read(cartControllerProvider.notifier).clear();

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return AlertDialog(
            key: const Key('order-success-dialog'),
            icon: const Icon(
              Icons.check_circle,
              size: 64,
              color: Color(0xFF34C759),
            ),
            title: const Text(
              'Đặt hàng thành công',
              textAlign: TextAlign.center,
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Mã đơn hàng: #${order['id']}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tổng thanh toán: '
                  '${checkoutCurrency.format(order['total'])}',
                ),
                const SizedBox(height: 12),
                const Text(
                  'TechZone sẽ liên hệ để xác nhận '
                  'đơn hàng trong thời gian sớm nhất.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              FilledButton(
                key: const Key('complete-order-button'),
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
                child: const Text('Hoàn tất'),
              ),
            ],
          );
        },
      );

      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            key: const Key('checkout-error'),
            backgroundColor: Theme.of(context).colorScheme.error,
            content: Text(error.toString()),
          ),
        );
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartControllerProvider);

    final total = ref.watch(cartTotalProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: const Text(
          'Thanh toán',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final desktop = constraints.maxWidth >= 800;

                final customerForm = _CustomerInformationForm(
                  formKey: _formKey,
                  nameController: _nameController,
                  phoneController: _phoneController,
                  addressController: _addressController,
                  validateName: _validateName,
                  validatePhone: _validatePhone,
                  validateAddress: _validateAddress,
                );

                final summary = _OrderSummary(
                  cart: cart,
                  total: total,
                  submitting: _submitting,
                  onPlaceOrder: _placeOrder,
                );

                if (desktop) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(28),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: customerForm),
                        const SizedBox(width: 24),
                        Expanded(flex: 2, child: summary),
                      ],
                    ),
                  );
                }

                return ListView(
                  padding: const EdgeInsets.all(18),
                  children: [customerForm, const SizedBox(height: 18), summary],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _CustomerInformationForm extends StatelessWidget {
  const _CustomerInformationForm({
    required this.formKey,
    required this.nameController,
    required this.phoneController,
    required this.addressController,
    required this.validateName,
    required this.validatePhone,
    required this.validateAddress,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController phoneController;
  final TextEditingController addressController;

  final String? Function(String?) validateName;
  final String? Function(String?) validatePhone;
  final String? Function(String?) validateAddress;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Thông tin nhận hàng',
                style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              const Text(
                'Vui lòng nhập chính xác thông tin '
                'để TechZone liên hệ giao hàng.',
                style: TextStyle(color: Color(0xFF6E6E73)),
              ),
              const SizedBox(height: 25),

              TextFormField(
                key: const Key('customer-name-field'),
                controller: nameController,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.name],
                decoration: const InputDecoration(
                  labelText: 'Họ và tên',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: validateName,
              ),
              const SizedBox(height: 16),

              TextFormField(
                key: const Key('phone-field'),
                controller: phoneController,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.telephoneNumber],
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9+]')),
                  LengthLimitingTextInputFormatter(12),
                ],
                decoration: const InputDecoration(
                  labelText: 'Số điện thoại',
                  hintText: '0901234567',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                validator: validatePhone,
              ),
              const SizedBox(height: 16),

              TextFormField(
                key: const Key('address-field'),
                controller: addressController,
                minLines: 3,
                maxLines: 5,
                textInputAction: TextInputAction.newline,
                autofillHints: const [AutofillHints.fullStreetAddress],
                decoration: const InputDecoration(
                  labelText: 'Địa chỉ nhận hàng',
                  hintText: 'Số nhà, đường, phường/xã, quận/huyện...',
                  alignLabelWithHint: true,
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
                validator: validateAddress,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderSummary extends StatelessWidget {
  const _OrderSummary({
    required this.cart,
    required this.total,
    required this.submitting,
    required this.onPlaceOrder,
  });

  final Map<int, CartLine> cart;
  final double total;
  final bool submitting;
  final VoidCallback onPlaceOrder;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Đơn hàng của bạn',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 18),

            ...cart.values.map((line) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 15),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        line.product.imageUrl,
                        width: 58,
                        height: 58,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const SizedBox(
                            width: 58,
                            height: 58,
                            child: Icon(Icons.devices),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            line.product.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Số lượng: ${line.quantity}',
                            style: const TextStyle(
                              color: Color(0xFF6E6E73),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      checkoutCurrency.format(line.total),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              );
            }),

            const Divider(height: 30),

            _SummaryRow(
              label: 'Tạm tính',
              value: checkoutCurrency.format(total),
            ),
            const SizedBox(height: 10),
            const _SummaryRow(label: 'Phí vận chuyển', value: 'Miễn phí'),

            const Divider(height: 30),

            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Tổng cộng',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ),
                Text(
                  checkoutCurrency.format(total),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),

            FilledButton(
              key: const Key('place-order-button'),
              onPressed: submitting ? null : onPlaceOrder,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF0071E3),
              ),
              child: submitting
                  ? const SizedBox.square(
                      dimension: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Xác nhận đặt hàng'),
            ),

            const SizedBox(height: 13),

            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline, size: 15, color: Color(0xFF6E6E73)),
                SizedBox(width: 6),
                Text(
                  'Thông tin của bạn được bảo mật',
                  style: TextStyle(color: Color(0xFF6E6E73), fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}
