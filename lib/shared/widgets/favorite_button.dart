import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/models/product.dart';
import '../../features/favorites/viewmodel/favorites_controller.dart';

class FavoriteButton extends StatelessWidget {
  const FavoriteButton({super.key, required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<FavoritesController>();
    final color = Theme.of(context).colorScheme.primary;

    return Obx(() {
      final isFavorite = controller.isFavorite(product.id);
      return IconButton(
        tooltip: isFavorite ? 'Remove from favorites' : 'Add to favorites',
        isSelected: isFavorite,
        color: color,
        style: IconButton.styleFrom(
          backgroundColor: isFavorite
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surfaceContainerLow,
        ),
        icon: const Icon(Icons.favorite_border),
        selectedIcon: const Icon(Icons.favorite),
        onPressed: () => controller.toggleFavorite(product),
      );
    });
  }
}
