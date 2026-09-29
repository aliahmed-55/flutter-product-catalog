import 'package:get/get.dart';

import '../../data/repositories/product_repository.dart';
import '../../features/favorites/view/favorites_screen.dart';
import '../../features/product_details/binding/product_details_binding.dart';
import '../../features/product_details/view/product_details_screen.dart';
import '../../features/product_list/view/product_list_screen.dart';
import 'app_routes.dart';

abstract final class AppPages {
  static List<GetPage<void>> pages(ProductRepository repository) => [
    GetPage<void>(name: AppRoutes.home, page: () => const ProductListScreen()),
    GetPage<void>(
      name: AppRoutes.favorites,
      page: () => const FavoritesScreen(),
    ),
    GetPage<void>(
      name: AppRoutes.productDetails,
      page: () => const ProductDetailsScreen(),
      binding: ProductDetailsBinding(repository),
    ),
  ];
}
