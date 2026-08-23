import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_shop_app/app/app.dart';

void main() {
  testWidgets('Flutter Shop App displays login page', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: FlutterShopApp()));

    await tester.pumpAndSettle();

    expect(find.text('Flutter Shop App'), findsOneWidget);

    expect(find.text('Sign in'), findsOneWidget);
  });
}
