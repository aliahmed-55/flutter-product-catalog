import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../shared/widgets/empty_view.dart';
import '../../../shared/widgets/product_card.dart';
import '../viewmodel/favorites_controller.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<FavoritesController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Favorites')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Obx(() {
              final products = controller.favoriteProducts;
              if (products.isEmpty) {
                return const EmptyView(
                  message: 'No favorite products yet.',
                  supportingText: 'Tap the heart on a product to save it here.',
                  icon: Icons.favorite_border,
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index];
                  return Padding(
                    key: ValueKey(product.id),
                    padding: EdgeInsets.only(
                      bottom: index == products.length - 1 ? 0 : 16,
                    ),
                    child: ProductCard(product: product),
                  );
                },
              );
            }),
          ),
        ),
      ),
    );
  }
}
