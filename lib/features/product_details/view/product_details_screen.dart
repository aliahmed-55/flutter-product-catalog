import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/gestures.dart';
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
      body: SafeArea(
        child: Obx(() {
          if (controller.isLoading.value) return const LoadingView();
          final error = controller.errorMessage.value;
          if (error != null) {
            return ErrorView(message: error, onRetry: controller.retry);
          }
          final product = controller.product.value;
          if (product == null) return const LoadingView();
          return _ProductDetails(product: product);
        }),
      ),
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
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: ColoredBox(
                  color: theme.colorScheme.surfaceContainerLow,
                  child: SizedBox(
                    height: MediaQuery.sizeOf(context).width < 600 ? 260 : 360,
                    child: images.isEmpty
                        ? const Center(
                            child: Icon(
                              Icons.image_not_supported_outlined,
                              size: 64,
                            ),
                          )
                        : ScrollConfiguration(
                            behavior: ScrollConfiguration.of(context).copyWith(
                              dragDevices: {
                                ...ScrollConfiguration.of(context).dragDevices,
                                PointerDeviceKind.mouse,
                              },
                            ),
                            child: PageView.builder(
                              itemCount: images.length,
                              itemBuilder: (context, index) => Padding(
                                padding: const EdgeInsets.all(16),
                                child: CachedNetworkImage(
                                  imageUrl: images[index],
                                  fit: BoxFit.contain,
                                  placeholder: (context, url) =>
                                      const LoadingView(),
                                  errorWidget: (context, url, error) =>
                                      const Center(
                                        child: Icon(
                                          Icons.image_not_supported_outlined,
                                          size: 64,
                                        ),
                                      ),
                                ),
                              ),
                            ),
                          ),
                  ),
                ),
              ),
              if (images.length > 1)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Center(
                    child: Text(
                      'Swipe to view ${images.length} images',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ),
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
              Wrap(
                spacing: 16,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    '\$${product.price.toStringAsFixed(2)}',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  Chip(
                    label: Text(
                      'Discount: ${product.discountPercentage.toStringAsFixed(1)}%',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    Icons.star_rounded,
                    size: 20,
                    color: Color(0xFF9A6700),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Rating: ${product.rating.toStringAsFixed(1)}',
                      style: theme.textTheme.titleSmall,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text('Description', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(product.description, style: theme.textTheme.bodyLarge),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Product information',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 16),
                        Text('Stock: ${product.stock}'),
                        const SizedBox(height: 12),
                        Text(
                          'Brand: ${brand == null || brand.isEmpty ? 'N/A' : brand}',
                        ),
                        const SizedBox(height: 12),
                        Text('Category: ${product.category}'),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
