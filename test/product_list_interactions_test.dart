import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:product_catalog/features/favorites/viewmodel/favorites_controller.dart';
import 'package:product_catalog/app/app.dart';
import 'package:product_catalog/core/network/api_exception.dart';
import 'package:product_catalog/data/models/product_page.dart';
import 'package:product_catalog/features/product_list/view/product_list_screen.dart';
import 'package:product_catalog/features/product_list/viewmodel/providers.dart';
import 'package:product_catalog/features/product_list/widgets/load_more_footer.dart';
import 'package:product_catalog/shared/widgets/error_view.dart';

import 'support/fake_product_repository.dart';

Widget app(FakeProductRepository repository) => ProviderScope(
  overrides: [productRepositoryProvider.overrideWithValue(repository)],
  child: const ProductCatalogApp(),
);

void main() {
  setUp(() => Get.put(FavoritesController(), permanent: true));
  tearDown(() => Get.reset());

  testWidgets(
    'Search debounces and category changes keep the text field synchronized',
    (tester) async {
      final repository = FakeProductRepository(() async => productPage(10));
      await tester.pumpWidget(app(repository));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'p');
      await tester.pump(const Duration(milliseconds: 200));
      await tester.enterText(find.byType(TextField), 'phone');
      await tester.pump(const Duration(milliseconds: 200));
      expect(repository.calls, 1);
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pumpAndSettle();
      expect(repository.requests.last.source, 'search:phone');
      await tester.tap(find.text('Beauty'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        '',
      );
      expect(repository.requests.last.source, 'category:beauty');
      await tester.enterText(find.byType(TextField), 'phone');
      await tester.pump(const Duration(milliseconds: 450));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Clear search'));
      await tester.pumpAndSettle();
      expect(repository.requests.last.source, 'category:beauty');
      await tester.enterText(find.byType(TextField), 'phone');
      await tester.tap(find.text('All'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        '',
      );
      expect(repository.requests.last.source, 'all');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Scrolling loads once, keeps products on failure and shows one SnackBar',
    (tester) async {
      final repository = FakeProductRepository(
        () async => productPage(10, total: 20),
      );
      final pending = Completer<ProductPage>();
      repository.onPage = (_, skip) =>
          skip == 0 ? Future.value(productPage(10, total: 20)) : pending.future;
      await tester.pumpWidget(app(repository));
      await tester.pumpAndSettle();
      await tester.drag(
        find.byKey(const ValueKey('product-list')),
        const Offset(0, -2500),
      );
      await tester.pump();
      expect(repository.calls, 2);
      expect(
        find.descendant(
          of: find.byType(LoadMoreFooter),
          matching: find.byType(CircularProgressIndicator),
        ),
        findsOneWidget,
      );
      pending.completeError(const ApiException('Next page unavailable'));
      await tester.pumpAndSettle();
      final container = ProviderScope.containerOf(
        tester.element(find.byType(ProductListScreen)),
      );
      expect(container.read(productListNotifierProvider).products.length, 10);
      expect(find.byType(ErrorView), findsNothing);
      expect(find.text('Next page unavailable'), findsOneWidget);
      ScaffoldMessenger.of(
        tester.element(find.byType(ProductListScreen)),
      ).clearSnackBars();
      await tester.pumpAndSettle();
      tester.element(find.byType(ProductListScreen)).markNeedsBuild();
      await tester.pumpAndSettle();
      expect(find.byType(SnackBar), findsNothing);
      repository.onPage = (_, skip) async =>
          productPage(10, skip: skip, total: 20);
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(container.read(productListNotifierProvider).products.length, 20);
      expect(repository.calls, 3);
      expect(container.read(productListNotifierProvider).hasMore, isFalse);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Pull to refresh reloads the selected source from zero', (
    tester,
  ) async {
    final repository = FakeProductRepository(
      () async => productPage(10, total: 20),
    );
    await tester.pumpWidget(app(repository));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Beauty'));
    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(const ValueKey('product-list')),
      const Offset(0, 500),
    );
    await tester.pumpAndSettle();
    expect(repository.calls, 3);
    expect(repository.requests.last, (source: 'category:beauty', skip: 0));
    expect(tester.takeException(), isNull);
  });
}
