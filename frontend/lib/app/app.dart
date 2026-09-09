import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../features/shop/presentation/shop_home_page.dart';

class FlutterShopApp extends StatelessWidget {
  const FlutterShopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TechZone Store',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(),
      home: const ShopHomePage(),
    );
  }
}
