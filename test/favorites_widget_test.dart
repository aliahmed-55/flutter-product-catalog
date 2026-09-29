import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:product_catalog/app/app.dart';
import 'package:product_catalog/features/favorites/viewmodel/favorites_controller.dart';
import 'package:product_catalog/features/product_list/view/product_list_screen.dart';
import 'package:product_catalog/features/product_list/viewmodel/providers.dart';
import 'package:product_catalog/shared/widgets/favorite_button.dart';
import 'package:product_catalog/shared/widgets/product_card.dart';

import 'support/fake_product_repository.dart';

void main() {
  setUp(() => Get.put(FavoritesController(), permanent: true));
  tearDown(() => Get.reset());

  testWidgets(
    'Hearts toggle without rebuilding cards or changing listing state',
    (tester) async {
      final repository = FakeProductRepository(() async => productPage(3));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [productRepositoryProvider.overrideWithValue(repository)],
          child: const ProductCatalogApp(),
        ),
      );
      await tester.pumpAndSettle();
      final container = ProviderScope.containerOf(
        tester.element(find.byType(ProductListScreen)),
      );
      final state = container.read(productListNotifierProvider);
      final card = find.byWidgetPredicate(
        (widget) => widget is ProductCard && widget.product.id == 1,
      );
      final heart = find.descendant(
        of: card,
        matching: find.byType(IconButton),
      );
      final rebuilt = <Type>[];
      final previousCallback = debugOnRebuildDirtyWidget;
      addTearDown(() => debugOnRebuildDirtyWidget = previousCallback);
      debugOnRebuildDirtyWidget = (element, builtOnce) {
        if (element.widget is ProductCard ||
            element.widget is ProductListScreen) {
          rebuilt.add(element.widget.runtimeType);
        }
      };

      expect(tester.widget<IconButton>(heart).isSelected, isFalse);
      await tester.tap(heart);
      await tester.pumpAndSettle();
      expect(tester.widget<IconButton>(heart).isSelected, isTrue);
      expect(Get.find<FavoritesController>().isFavorite(1), isTrue);
      await tester.tap(heart);
      await tester.pumpAndSettle();
      expect(tester.widget<IconButton>(heart).isSelected, isFalse);
      expect(container.read(productListNotifierProvider), same(state));
      expect(repository.calls, 1);
      expect(repository.categoryCalls, 1);
      expect(rebuilt, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Favorites survive search, categories, paging, refresh and list remount',
    (tester) async {
      final repository = FakeProductRepository(
        () async => productPage(10, total: 30),
      );
      repository.onPage = (source, skip) async => source.startsWith('search:')
          ? productPage(1, ids: [99])
          : productPage(10, skip: skip, total: 30);
      final controller = Get.find<FavoritesController>();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [productRepositoryProvider.overrideWithValue(repository)],
          child: const ProductCatalogApp(),
        ),
      );
      await tester.pumpAndSettle();
      final container = ProviderScope.containerOf(
        tester.element(find.byType(ProductListScreen)),
      );
      final notifier = container.read(productListNotifierProvider.notifier);
      final card = find.byWidgetPredicate(
        (widget) => widget is ProductCard && widget.product.id == 1,
      );
      final heart = find.descendant(
        of: card,
        matching: find.byType(IconButton),
      );
      await tester.tap(heart);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'phone');
      await tester.pump(const Duration(milliseconds: 450));
      await tester.pumpAndSettle();
      expect(find.text('Product 99'), findsOneWidget);
      expect(controller.isFavorite(1), isTrue);
      await tester.tap(find.byTooltip('Clear search'));
      await tester.pumpAndSettle();
      expect(tester.widget<IconButton>(heart).isSelected, isTrue);
      await tester.tap(find.text('Beauty'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('All'));
      await tester.pumpAndSettle();
      expect(tester.widget<IconButton>(heart).isSelected, isTrue);
      await notifier.loadMore();
      await tester.pumpAndSettle();
      expect(container.read(productListNotifierProvider).products.length, 20);
      expect(tester.widget<IconButton>(heart).isSelected, isTrue);
      await notifier.refresh();
      await tester.pumpAndSettle();
      expect(tester.widget<IconButton>(heart).isSelected, isTrue);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      expect(Get.find<FavoritesController>(), same(controller));
      await tester.pumpWidget(
        GetMaterialApp(
          home: Scaffold(
            body: FavoriteButton(product: productPage(1).products.single),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.widget<IconButton>(find.byType(IconButton)).isSelected,
        isTrue,
      );
      expect(controller.favoriteProducts.length, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Two buttons for the same product share one favorite state', (
    tester,
  ) async {
    final product = productPage(1).products.single;
    await tester.pumpWidget(
      GetMaterialApp(
        home: Scaffold(
          body: Row(
            children: [
              FavoriteButton(product: product),
              FavoriteButton(product: product),
            ],
          ),
        ),
      ),
    );
    await tester.tap(find.byType(IconButton).first);
    await tester.pumpAndSettle();
    expect(
      tester
          .widgetList<IconButton>(find.byType(IconButton))
          .every((button) => button.isSelected == true),
      isTrue,
    );
    await tester.tap(find.byType(IconButton).last);
    await tester.pumpAndSettle();
    expect(
      tester
          .widgetList<IconButton>(find.byType(IconButton))
          .every((button) => button.isSelected == false),
      isTrue,
    );
    expect(Get.find<FavoritesController>().favoriteProducts, isEmpty);
  });
}
