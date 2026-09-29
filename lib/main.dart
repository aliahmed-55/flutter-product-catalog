import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';

import 'app/app.dart';
import 'features/favorites/viewmodel/favorites_controller.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  Get.put(FavoritesController(), permanent: true);
  runApp(const ProviderScope(child: ProductCatalogApp()));
}
