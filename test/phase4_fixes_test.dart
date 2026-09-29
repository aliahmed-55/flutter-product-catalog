import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:product_catalog/app/app.dart';
import 'package:product_catalog/core/network/api_exception.dart';
import 'package:product_catalog/data/models/product_page.dart';
import 'package:product_catalog/features/product_list/view/product_list_screen.dart';
import 'package:product_catalog/features/product_list/viewmodel/providers.dart';
import 'package:product_catalog/shared/widgets/error_view.dart';

import 'support/fake_product_repository.dart';

Widget app(FakeProductRepository repository) => ProviderScope(
  overrides: [productRepositoryProvider.overrideWithValue(repository)],
  child: const ProductCatalogApp(),
);

void main() {
  for (final source in ['all', 'category:beauty', 'search:phone']) {
    testWidgets('Mouse refresh replaces a short list for $source', (
      tester,
    ) async {
      final repository = FakeProductRepository(() async => productPage(1));
      await tester.pumpWidget(app(repository));
      await tester.pumpAndSettle();
      final container = ProviderScope.containerOf(
        tester.element(find.byType(ProductListScreen)),
      );
      final notifier = container.read(productListNotifierProvider.notifier);
      if (source == 'category:beauty') {
        await tester.tap(find.text('Beauty'));
      } else if (source == 'search:phone') {
        await tester.tap(find.text('Beauty'));
        await tester.enterText(find.byType(TextField), 'phone');
        await tester.pump(const Duration(milliseconds: 450));
      }
      await tester.pumpAndSettle();
      final calls = repository.calls;
      final response = Completer<ProductPage>();
      repository.onPage = (_, _) => response.future;
      await tester.drag(
        find.byKey(const ValueKey('product-list')),
        const Offset(0, 500),
        kind: PointerDeviceKind.mouse,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(repository.calls, calls + 1);
      expect(repository.requests.last, (source: source, skip: 0));
      expect(container.read(productListNotifierProvider).isRefreshing, isTrue);
      expect(find.text('Product 1'), findsOneWidget);
      final completion = notifier.refresh();
      var completed = false;
      completion.then((_) => completed = true);
      await tester.pump();
      expect(completed, isFalse);
      expect(repository.calls, calls + 1);
      response.complete(productPage(1, total: 12, ids: [99]));
      await tester.pumpAndSettle();
      expect(find.text('Product 99'), findsOneWidget);
      expect(find.text('Product 1'), findsNothing);
      final state = container.read(productListNotifierProvider);
      expect(state.isRefreshing, isFalse);
      expect(state.skip, 0);
      expect(state.total, 12);
      expect(state.hasMore, isTrue);
      expect(state.loadMoreError, isNull);
      expect(state.searchQuery, source == 'search:phone' ? 'phone' : '');
      expect(state.selectedCategory?.slug, source == 'all' ? null : 'beauty');
      expect(completed, isTrue);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('One initial error and Retry recovers products and categories', (
    tester,
  ) async {
    const message =
        'Unable to reach the server. Please check your connection and try again.';
    final repository = FakeProductRepository(
      () async => throw const ApiException(message),
    );
    repository.categoryResponse = () async => throw const ApiException(message);
    await tester.pumpWidget(app(repository));
    await tester.pumpAndSettle();
    expect(find.byType(ErrorView), findsOneWidget);
    expect(find.text(message), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    repository.response = () async => productPage(1);
    repository.categoryResponse = () async => [beauty];
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('Product 1'), findsOneWidget);
    expect(find.text('Beauty'), findsOneWidget);
    expect(repository.calls, 2);
    expect(repository.categoryCalls, 2);
    expect(find.byType(ErrorView), findsNothing);
  });

  testWidgets('Category-only failure remains visible with its own retry', (
    tester,
  ) async {
    final repository = FakeProductRepository(() async => productPage(1));
    repository.categoryResponse = () async =>
        throw const ApiException('Categories unavailable');
    await tester.pumpWidget(app(repository));
    await tester.pumpAndSettle();
    expect(find.text('Categories unavailable'), findsOneWidget);
    expect(find.text('Product 1'), findsOneWidget);
    repository.categoryResponse = () async => [beauty];
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(repository.calls, 1);
    expect(find.text('Beauty'), findsOneWidget);
  });
}
