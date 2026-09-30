import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:product_catalog/app/app.dart';
import 'package:product_catalog/data/models/product.dart';
import 'package:product_catalog/features/favorites/viewmodel/favorites_controller.dart';
import 'package:product_catalog/features/product_list/viewmodel/providers.dart';

import 'support/fake_product_repository.dart';

class DetailsRepository extends FakeProductRepository {
  DetailsRepository() : super(() async => productPage(1));

  final requestedIds = <int>[];

  @override
  Future<Product> getProduct(int id) async {
    requestedIds.add(id);
    return productPage(1, ids: [id]).products.single;
  }
}

void main() {
  setUp(() => Get.put(FavoritesController(), permanent: true));
  tearDown(() => Get.reset());

  testWidgets(
    'Details fetches by ID and favorite changes appear back in List',
    (tester) async {
      final repository = DetailsRepository();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [productRepositoryProvider.overrideWithValue(repository)],
          child: const ProductCatalogApp(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Add to favorites'));
      await tester.pumpAndSettle();
      expect(repository.requestedIds, isEmpty);

      await tester.tap(find.text('Product 1'));
      await tester.pumpAndSettle();
      expect(repository.requestedIds, [1]);
      expect(find.text('Test product'), findsOneWidget);
      expect(find.byTooltip('Remove from favorites'), findsOneWidget);

      await tester.tap(find.byTooltip('Remove from favorites'));
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Product Catalog'), findsOneWidget);
      expect(find.byTooltip('Add to favorites'), findsOneWidget);
      expect(repository.calls, 1);
      expect(repository.requestedIds, [1]);
    },
  );
}
