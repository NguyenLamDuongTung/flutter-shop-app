import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() {
    return _LoginPageState();
  }
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController(
    text: 'customer@shop.test',
  );

  final TextEditingController _passwordController = TextEditingController(
    text: 'Test123!',
  );

  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();

    super.dispose();
  }

  Future<void> _submitLogin() async {
    FocusScope.of(context).unfocus();

    final valid = _formKey.currentState?.validate() ?? false;

    if (!valid) {
      return;
    }

    final success = await ref
        .read(authControllerProvider.notifier)
        .login(_emailController.text.trim(), _passwordController.text);

    if (!mounted) {
      return;
    }

    if (success) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: const Text('Đăng nhập'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(22),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(30),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Center(
                          child: CircleAvatar(
                            radius: 34,
                            backgroundColor: Color(0xFF1D1D1F),
                            child: Icon(
                              Icons.bolt_rounded,
                              size: 39,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        const Text(
                          'Đăng nhập TechZone',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFF1D1D1F),
                            fontSize: 27,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),

                        const Text(
                          'Đăng nhập để thanh toán và '
                          'theo dõi đơn hàng.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFF6E6E73),
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 28),

                        TextFormField(
                          key: const Key('email-field'),
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          validator: validateEmail,
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          key: const Key('password-field'),
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          decoration: InputDecoration(
                            labelText: 'Mật khẩu',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              key: const Key('toggle-password-button'),
                              tooltip: _obscurePassword
                                  ? 'Hiện mật khẩu'
                                  : 'Ẩn mật khẩu',
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            ),
                          ),
                          validator: validatePassword,
                          onFieldSubmitted: (_) {
                            if (!authState.isLoading) {
                              _submitLogin();
                            }
                          },
                        ),

                        if (authState.hasError) ...[
                          const SizedBox(height: 15),
                          Semantics(
                            liveRegion: true,
                            child: Container(
                              key: const Key('login-error'),
                              padding: const EdgeInsets.all(13),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .errorContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                authState.error.toString(),
                                style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onErrorContainer,
                                ),
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(height: 22),

                        FilledButton(
                          key: const Key('login-button'),
                          onPressed: authState.isLoading ? null : _submitLogin,
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF0071E3),
                          ),
                          child: authState.isLoading
                              ? const SizedBox.square(
                                  dimension: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Đăng nhập'),
                        ),

                        const SizedBox(height: 22),
                        const Divider(),
                        const SizedBox(height: 14),

                        const Text(
                          'Tài khoản dùng thử',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 7),

                        const SelectableText(
                          'customer@shop.test\nTest123!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFF6E6E73),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String? validateEmail(String? value) {
  final email = value?.trim() ?? '';

  if (email.isEmpty) {
    return 'Email không được để trống';
  }

  final emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  if (!emailPattern.hasMatch(email)) {
    return 'Email không hợp lệ';
  }

  return null;
}

String? validatePassword(String? value) {
  final password = value ?? '';

  if (password.isEmpty) {
    return 'Mật khẩu không được để trống';
  }

  if (password.length < 6) {
    return 'Mật khẩu phải có ít nhất 6 ký tự';
  }

  return null;
}
