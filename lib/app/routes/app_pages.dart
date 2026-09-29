import 'package:get/get.dart';

import '../../features/product_list/view/product_list_screen.dart';
import 'app_routes.dart';

abstract final class AppPages {
  static final pages = <GetPage<void>>[
    GetPage<void>(name: AppRoutes.home, page: () => const ProductListScreen()),
  ];
}
