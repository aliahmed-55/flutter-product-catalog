import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:product_catalog/app/app.dart';
import 'package:product_catalog/data/models/product.dart';
import 'package:product_catalog/data/models/product_page.dart';
import 'package:product_catalog/features/favorites/viewmodel/favorites_controller.dart';
import 'package:product_catalog/features/product_list/viewmodel/providers.dart';
import 'package:product_catalog/shared/widgets/favorite_button.dart';
import 'package:product_catalog/shared/widgets/product_card.dart';

import 'support/fake_product_repository.dart';

const longProduct = Product(
  id: 1,
  title:
      'A thoughtfully designed everyday product with an unusually long descriptive title',
  description:
      'A detailed description that should remain readable and wrap naturally on a smaller screen without clipping any important product information.',
  price: 1299.99,
  discountPercentage: 12.5,
  rating: 4.8,
  stock: 42,
  brand: 'A brand with a particularly long name',
  category: 'A long category name that should fit safely',
  thumbnail: '',
  images: [],
);

class LayoutRepository extends FakeProductRepository {
  LayoutRepository()
    : super(
        () async => const ProductPage(
          products: [longProduct],
          total: 1,
          skip: 0,
          limit: 10,
        ),
      );

  @override
  Future<Product> getProduct(int id) async => longProduct;
}

void main() {
  setUp(() => Get.put(FavoritesController(), permanent: true));
  tearDown(() => Get.reset());

  for (final width in [320.0, 768.0, 1440.0]) {
    testWidgets(
      'List, Details and Favorites handle long text at width $width',
      (tester) async {
        await tester.binding.setSurfaceSize(Size(width, 900));
        tester.platformDispatcher.textScaleFactorTestValue = 1.5;
        addTearDown(() async {
          tester.platformDispatcher.clearTextScaleFactorTestValue();
          await tester.binding.setSurfaceSize(null);
        });
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              productRepositoryProvider.overrideWithValue(LayoutRepository()),
            ],
            child: const ProductCatalogApp(),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(
          tester.getSize(find.byType(ProductCard)).width,
          lessThanOrEqualTo(800),
        );
        await tester.tap(find.byType(FavoriteButton));
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('Open favorites'));
        await tester.pumpAndSettle();
        expect(find.byType(ProductCard), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.tap(find.text(longProduct.title));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.ensureVisible(
          find.text('Category: ${longProduct.category}'),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text(longProduct.description), findsOneWidget);
      },
    );
  }
}
