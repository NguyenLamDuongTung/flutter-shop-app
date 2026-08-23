import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../features/auth/presentation/login_page.dart';

class FlutterShopApp extends StatelessWidget {
  const FlutterShopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Shop App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(),
      home: const LoginPage(),
    );
  }
}
