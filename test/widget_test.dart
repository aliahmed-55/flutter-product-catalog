import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:product_catalog/app/app.dart';
import 'package:product_catalog/core/network/api_exception.dart';
import 'package:product_catalog/data/models/product_page.dart';
import 'package:product_catalog/features/favorites/viewmodel/favorites_controller.dart';
import 'package:product_catalog/features/product_list/viewmodel/providers.dart';
import 'package:product_catalog/shared/widgets/error_view.dart';
import 'package:product_catalog/shared/widgets/loading_view.dart';

import 'support/fake_product_repository.dart';

Widget createApp(FakeProductRepository repository) => ProviderScope(
  overrides: [productRepositoryProvider.overrideWithValue(repository)],
  child: const ProductCatalogApp(),
);

void main() {
  setUp(() => Get.put(FavoritesController(), permanent: true));
  tearDown(() => Get.reset());

  testWidgets('Listing shows loading, then products from one request', (
    tester,
  ) async {
    final response = Completer<ProductPage>();
    final repository = FakeProductRepository(() => response.future);

    await tester.pumpWidget(createApp(repository));
    await tester.pump();
    expect(find.byType(LoadingView), findsOneWidget);
    expect(repository.calls, 1);

    response.complete(productPage(2));
    await tester.pumpAndSettle();
    expect(find.byType(LoadingView), findsNothing);
    expect(find.text('Product 1'), findsOneWidget);
    expect(find.text('Product 2'), findsOneWidget);
    expect(repository.calls, 1);
  });

  testWidgets('Listing Retry recovers from an API error', (tester) async {
    final repository = FakeProductRepository(
      () async => throw const ApiException(
        'The server is unavailable. Please try again later.',
      ),
    );
    await tester.pumpWidget(createApp(repository));
    await tester.pumpAndSettle();
    expect(find.byType(ErrorView), findsOneWidget);
    expect(
      find.text('The server is unavailable. Please try again later.'),
      findsOneWidget,
    );

    repository.response = () async => productPage(1);
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.byType(ErrorView), findsNothing);
    expect(find.text('Product 1'), findsOneWidget);
    expect(repository.calls, 2);
  });
}
