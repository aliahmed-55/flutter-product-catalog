import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/models/product.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/favorite_button.dart';
import '../../../shared/widgets/loading_view.dart';
import '../viewmodel/product_details_controller.dart';

class ProductDetailsScreen extends GetView<ProductDetailsController> {
  const ProductDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Product details')),
      body: Obx(() {
        if (controller.isLoading.value) return const LoadingView();
        final error = controller.errorMessage.value;
        if (error != null) {
          return ErrorView(message: error, onRetry: controller.retry);
        }
        final product = controller.product.value;
        if (product == null) return const LoadingView();
        return _ProductDetails(product: product);
      }),
    );
  }
}

class _ProductDetails extends StatelessWidget {
  const _ProductDetails({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final images = product.images
        .where((image) => image.trim().isNotEmpty)
        .toList();
    if (images.isEmpty && product.thumbnail.trim().isNotEmpty) {
      images.add(product.thumbnail);
    }
    final brand = product.brand?.trim();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 280,
                child: images.isEmpty
                    ? const Center(
                        child: Icon(
                          Icons.image_not_supported_outlined,
                          size: 64,
                        ),
                      )
                    : PageView.builder(
                        itemCount: images.length,
                        itemBuilder: (context, index) => CachedNetworkImage(
                          imageUrl: images[index],
                          fit: BoxFit.contain,
                          placeholder: (context, url) => const LoadingView(),
                          errorWidget: (context, url, error) => const Center(
                            child: Icon(
                              Icons.image_not_supported_outlined,
                              size: 64,
                            ),
                          ),
                        ),
                      ),
              ),
              if (images.length > 1)
                Center(child: Text('Swipe to view ${images.length} images')),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      product.title,
                      style: theme.textTheme.headlineSmall,
                    ),
                  ),
                  FavoriteButton(product: product),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '\$${product.price.toStringAsFixed(2)}',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text(product.description, style: theme.textTheme.bodyLarge),
              const SizedBox(height: 24),
              Wrap(
                spacing: 16,
                runSpacing: 12,
                children: [
                  Text(
                    'Discount: ${product.discountPercentage.toStringAsFixed(1)}%',
                  ),
                  Text('Rating: ${product.rating.toStringAsFixed(1)}'),
                  Text('Stock: ${product.stock}'),
                  Text(
                    'Brand: ${brand == null || brand.isEmpty ? 'N/A' : brand}',
                  ),
                  Text('Category: ${product.category}'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
