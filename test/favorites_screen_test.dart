import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:product_catalog/app/app.dart';
import 'package:product_catalog/app/routes/app_routes.dart';
import 'package:product_catalog/data/models/product.dart';
import 'package:product_catalog/features/favorites/viewmodel/favorites_controller.dart';
import 'package:product_catalog/features/product_details/viewmodel/product_details_controller.dart';
import 'package:product_catalog/features/product_list/viewmodel/providers.dart';
import 'package:product_catalog/shared/widgets/favorite_button.dart';
import 'package:product_catalog/shared/widgets/product_card.dart';

import 'support/fake_product_repository.dart';

class FavoritesRepository extends FakeProductRepository {
  FavoritesRepository() : super(() async => productPage(4));

  final detailIds = <int>[];

  @override
  Future<Product> getProduct(int id) async {
    detailIds.add(id);
    return productPage(1, ids: [id]).products.single;
  }
}

Finder heart(int id) => find.descendant(
  of: find.byWidgetPredicate(
    (widget) => widget is ProductCard && widget.product.id == id,
  ),
  matching: find.byType(FavoriteButton),
);

void main() {
  setUp(() => Get.put(FavoritesController(), permanent: true));
  tearDown(() => Get.reset());

  testWidgets(
    'Favorites synchronize with List and Details without extra requests',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final repository = FavoritesRepository();
      final controller = Get.find<FavoritesController>();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [productRepositoryProvider.overrideWithValue(repository)],
          child: const ProductCatalogApp(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Open favorites'));
      await tester.pumpAndSettle();
      expect(find.text('No favorite products yet.'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      for (final id in [1, 2, 3]) {
        await tester.tap(heart(id));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.byTooltip('Open favorites'));
      await tester.pumpAndSettle();
      expect(find.byType(ProductCard), findsNWidgets(3));
      await tester.tap(heart(2));
      await tester.pumpAndSettle();
      expect(find.text('Product 2'), findsNothing);
      expect(Get.currentRoute, AppRoutes.favorites);
      expect(repository.detailIds, isEmpty);
      expect(controller.favoriteProducts.map((product) => product.id), [1, 3]);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byTooltip('Remove from favorites'), findsNWidgets(2));
      await tester.tap(find.text('Product 1'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Remove from favorites'), findsOneWidget);
      await tester.tap(find.byType(FavoriteButton));
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Product 4'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(FavoriteButton));
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Open favorites'));
      await tester.pumpAndSettle();
      expect(find.text('Product 1'), findsNothing);
      expect(find.text('Product 3'), findsOneWidget);
      expect(find.text('Product 4'), findsOneWidget);
      await tester.tap(find.text('Product 4'));
      await tester.pumpAndSettle();
      expect(Get.currentRoute, '/products/4');
      expect(Get.arguments, isNull);
      expect(repository.detailIds, [1, 4, 4]);
      await tester.tap(find.byType(FavoriteButton));
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(Get.currentRoute, AppRoutes.favorites);
      expect(Get.isRegistered<ProductDetailsController>(), isFalse);
      expect(find.text('Product 4'), findsNothing);
      await tester.tap(heart(3));
      await tester.pumpAndSettle();
      expect(find.text('No favorite products yet.'), findsOneWidget);
      expect(Get.find<FavoritesController>(), same(controller));
      expect(repository.calls, 1);
      expect(repository.categoryCalls, 1);
      expect(repository.detailIds, [1, 4, 4]);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Visible favorites reacts to shared additions and removals on a narrow screen',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 700));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final repository = FavoritesRepository();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [productRepositoryProvider.overrideWithValue(repository)],
          child: const ProductCatalogApp(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Open favorites'));
      await tester.pumpAndSettle();
      final controller = Get.find<FavoritesController>();
      controller.addFavorite(productPage(1).products.single);
      await tester.pumpAndSettle();
      expect(find.text('Product 1'), findsOneWidget);
      controller.removeFavorite(1);
      await tester.pumpAndSettle();
      expect(find.text('No favorite products yet.'), findsOneWidget);
      expect(repository.calls, 1);
      expect(repository.detailIds, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );
}
