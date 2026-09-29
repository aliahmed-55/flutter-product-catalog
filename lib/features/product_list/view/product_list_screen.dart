import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_strings.dart';
import '../../../shared/widgets/empty_view.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../../shared/widgets/product_card.dart';
import '../viewmodel/providers.dart';

class ProductListScreen extends ConsumerWidget {
  const ProductListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(productListNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.appName)),
      body: SafeArea(
        child: switch (state) {
          _ when state.isLoading => const LoadingView(),
          _ when state.errorMessage != null => ErrorView(
            message: state.errorMessage!,
            onRetry: () =>
                ref.read(productListNotifierProvider.notifier).loadProducts(),
          ),
          _ when state.isEmpty => const EmptyView(
            message: AppStrings.noProducts,
          ),
          _ => Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: state.products.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final product = state.products[index];
                  return ProductCard(
                    key: ValueKey(product.id),
                    product: product,
                  );
                },
              ),
            ),
          ),
        },
      ),
    );
  }
}
