import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';

import '../core/constants/app_strings.dart';
import '../core/theme/app_theme.dart';
import '../features/product_list/viewmodel/providers.dart';
import 'routes/app_pages.dart';
import 'routes/app_routes.dart';

class ProductCatalogApp extends ConsumerWidget {
  const ProductCatalogApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GetMaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: AppRoutes.home,
      getPages: AppPages.pages(ref.watch(productRepositoryProvider)),
    );
  }
}
