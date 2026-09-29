import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:product_catalog/app/app.dart';

void main() {
  testWidgets('App launches into the welcome screen', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: ProductCatalogApp()));
    await tester.pumpAndSettle();

    expect(find.text('Product Catalog'), findsOneWidget);
    expect(find.text('A place for your next great find.'), findsOneWidget);
    expect(find.text('Your catalog is coming soon.'), findsOneWidget);
    expect(find.byIcon(Icons.shopping_bag_outlined), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
