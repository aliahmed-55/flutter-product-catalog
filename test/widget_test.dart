import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:product_catalog/features/favorites/viewmodel/favorites_controller.dart';

import 'package:product_catalog/app/app.dart';
import 'package:product_catalog/core/network/api_exception.dart';
import 'support/fake_product_repository.dart';

import 'package:product_catalog/data/models/product_page.dart';
import 'package:product_catalog/data/repositories/product_repository.dart';
import 'package:product_catalog/features/product_list/view/product_list_screen.dart';
import 'package:product_catalog/features/product_list/viewmodel/providers.dart';
import 'package:product_catalog/shared/widgets/empty_view.dart';
import 'package:product_catalog/shared/widgets/error_view.dart';
import 'package:product_catalog/shared/widgets/loading_view.dart';
import 'package:product_catalog/shared/widgets/product_card.dart';

void main() {
  setUp(() => Get.put(FavoritesController(), permanent: true));
  tearDown(() => Get.reset());

  testWidgets('Loads ten products once and renders cards on a narrow screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final response = Completer<ProductPage>();
    final repository = FakeProductRepository(() => response.future);

    await tester.pumpWidget(createApp(repository));
    expect(find.byType(LoadingView), findsOneWidget);
    await tester.pump();
    expect(repository.calls, 1);

    tester.element(find.byType(ProductListScreen)).markNeedsBuild();
    await tester.pump();
    expect(repository.calls, 1);

    response.complete(productPage(10));
    await tester.pumpAndSettle();

    expect(find.text('Product Catalog'), findsOneWidget);
    expect(find.byType(LoadingView), findsNothing);
    expect(
      tester.widget<ListView>(find.byType(ListView)).semanticChildCount,
      11,
    );
    final firstCard = find.byWidgetPredicate(
      (widget) => widget is ProductCard && widget.product.id == 1,
    );
    expect(
      find.descendant(of: firstCard, matching: find.text('Product 1')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: firstCard, matching: find.text('\$9.99')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: firstCard, matching: find.text('4.5')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: firstCard, matching: find.text('beauty')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: firstCard,
        matching: find.byIcon(Icons.image_not_supported_outlined),
      ),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(
      find.text('Product 10'),
      300,
      scrollable: find.descendant(
        of: find.byKey(const ValueKey('product-list')),
        matching: find.byType(Scrollable),
      ),
    );
    expect(find.text('Product 10'), findsOneWidget);
    expect(repository.calls, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Shows an API error and retries through loading to success', (
    tester,
  ) async {
    final firstResponse = Completer<ProductPage>();
    final retryResponse = Completer<ProductPage>();
    final repository = FakeProductRepository(() => firstResponse.future);
    await tester.pumpWidget(createApp(repository));
    await tester.pump();
    firstResponse.completeError(
      const ApiException('Check your internet connection and try again.'),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ErrorView), findsOneWidget);
    expect(
      find.text('Check your internet connection and try again.'),
      findsOneWidget,
    );
    repository.response = () => retryResponse.future;
    await tester.tap(find.text('Retry'));
    await tester.pump();
    expect(find.byType(LoadingView), findsOneWidget);
    expect(repository.calls, 2);

    retryResponse.complete(productPage(1));
    await tester.pumpAndSettle();
    expect(find.text('Product 1'), findsOneWidget);
    expect(find.byType(ErrorView), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Shows an empty view for an empty product page', (tester) async {
    final repository = FakeProductRepository(() async => productPage(0));
    await tester.pumpWidget(createApp(repository));
    await tester.pumpAndSettle();

    expect(find.byType(EmptyView), findsOneWidget);
    expect(find.text('No products found.'), findsOneWidget);
    expect(find.byType(ProductCard), findsNothing);
    expect(repository.calls, 1);
  });

  testWidgets('Hides technical details for unexpected failures', (
    tester,
  ) async {
    final repository = FakeProductRepository(
      () async => throw StateError('private details'),
    );
    await tester.pumpWidget(createApp(repository));
    await tester.pumpAndSettle();

    expect(
      find.text('Unable to load products. Please try again.'),
      findsOneWidget,
    );
    expect(find.textContaining('private details'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

Widget createApp(ProductRepository repository) {
  return ProviderScope(
    overrides: [productRepositoryProvider.overrideWithValue(repository)],
    child: const ProductCatalogApp(),
  );
}
