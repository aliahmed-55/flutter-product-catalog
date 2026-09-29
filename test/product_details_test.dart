import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:product_catalog/app/app.dart';
import 'package:product_catalog/core/network/api_exception.dart';
import 'package:product_catalog/data/models/product.dart';
import 'package:product_catalog/features/favorites/viewmodel/favorites_controller.dart';
import 'package:product_catalog/features/product_details/view/product_details_screen.dart';
import 'package:product_catalog/features/product_details/viewmodel/product_details_controller.dart';
import 'package:product_catalog/features/product_list/viewmodel/providers.dart';
import 'package:product_catalog/shared/widgets/favorite_button.dart';
import 'package:product_catalog/shared/widgets/loading_view.dart';

import 'support/fake_product_repository.dart';

class DetailsRepository extends FakeProductRepository {
  DetailsRepository() : super(() async => productPage(2));

  final ids = <int>[];
  Future<Product> Function(int)? details;

  @override
  Future<Product> getProduct(int id) {
    ids.add(id);
    return details?.call(id) ??
        Future.value(productPage(1, ids: [id]).products.single);
  }
}

void main() {
  setUp(() => Get.put(FavoritesController(), permanent: true));
  tearDown(() => Get.reset());

  testWidgets('ID navigation, loading, shared favorites and route disposal', (
    tester,
  ) async {
    final repository = DetailsRepository();
    final pending = Completer<Product>();
    repository.details = (_) => pending.future;
    final favorites = Get.find<FavoritesController>();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [productRepositoryProvider.overrideWithValue(repository)],
        child: const ProductCatalogApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(FavoriteButton).first);
    await tester.pumpAndSettle();
    expect(repository.ids, isEmpty);
    expect(find.byType(ProductDetailsScreen), findsNothing);
    await tester.tap(find.text('Product 1'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(Get.currentRoute, '/products/1');
    expect(Get.arguments, isNull);
    expect(repository.ids, [1]);
    expect(find.byType(LoadingView), findsOneWidget);
    final controller = Get.find<ProductDetailsController>();
    expect(controller.repository, same(repository));
    pending.complete(productPage(1).products.single);
    await tester.pumpAndSettle();
    expect(find.text('Test product'), findsOneWidget);
    expect(find.text('Brand: N/A'), findsOneWidget);
    expect(find.text('Stock: 20'), findsOneWidget);
    expect(find.byIcon(Icons.image_not_supported_outlined), findsOneWidget);
    expect(find.byTooltip('Remove from favorites'), findsOneWidget);
    await tester.tap(find.byType(FavoriteButton));
    await tester.pumpAndSettle();
    expect(favorites.isFavorite(1), isFalse);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(controller.isClosed, isTrue);
    expect(Get.isRegistered<ProductDetailsController>(), isFalse);
    expect(Get.find<FavoritesController>(), same(favorites));
    expect(find.byTooltip('Remove from favorites'), findsNothing);
    repository.details = null;
    await tester.tap(find.text('Product 2'));
    await tester.pumpAndSettle();
    expect(repository.ids, [1, 2]);
    expect(Get.find<ProductDetailsController>(), isNot(same(controller)));
    await tester.tap(find.byType(FavoriteButton));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(favorites.isFavorite(2), isTrue);
    expect(find.byTooltip('Remove from favorites'), findsOneWidget);
    expect(repository.calls, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Details API errors retry the same ID without leaving the route',
    (tester) async {
      final repository = DetailsRepository();
      repository.details = (_) async =>
          throw const ApiException('Product unavailable. Please try again.');
      await tester.pumpWidget(
        ProviderScope(
          overrides: [productRepositoryProvider.overrideWithValue(repository)],
          child: const ProductCatalogApp(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Product 1'));
      await tester.pumpAndSettle();
      expect(
        find.text('Product unavailable. Please try again.'),
        findsOneWidget,
      );
      repository.details = null;
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(repository.ids, [1, 1]);
      expect(Get.currentRoute, '/products/1');
      expect(find.text('Test product'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  test(
    'Duplicate requests, unexpected failures, invalid IDs and late completion',
    () async {
      final repository = DetailsRepository();
      final pending = Completer<Product>();
      repository.details = (_) => pending.future;
      final controller = ProductDetailsController(
        repository: repository,
        productId: 1,
      );
      final request = controller.retry();
      await controller.retry();
      expect(repository.ids, [1]);
      controller.onDelete();
      pending.complete(productPage(1).products.single);
      await request;
      expect(controller.product.value, isNull);
      final invalid = ProductDetailsController(
        repository: repository,
        productId: 0,
      );
      await invalid.retry();
      expect(invalid.errorMessage.value, 'This product link is invalid.');
      expect(repository.ids, [1]);
      repository.details = (_) async =>
          throw StateError('Private technical details');
      final failed = ProductDetailsController(
        repository: repository,
        productId: 2,
      );
      await failed.retry();
      expect(
        failed.errorMessage.value,
        'Unable to load this product. Please try again.',
      );
      expect(failed.isLoading.value, isFalse);
    },
  );
}
