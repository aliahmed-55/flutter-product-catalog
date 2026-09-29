import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/network/api_exception.dart';
import 'product_list_state.dart';
import 'providers.dart';

class ProductListNotifier extends Notifier<ProductListState> {
  @override
  ProductListState build() {
    Future.microtask(_fetchProducts);
    return const ProductListState(isLoading: true);
  }

  Future<void> loadProducts() async {
    if (state.isLoading) return;

    state = const ProductListState(isLoading: true);
    await _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    if (!ref.mounted) return;

    final repository = ref.read(productRepositoryProvider);
    try {
      final page = await repository.getProducts(limit: 10, skip: 0);
      if (!ref.mounted) return;

      state = ProductListState(products: page.products);
    } on ApiException catch (error) {
      if (!ref.mounted) return;

      state = ProductListState(errorMessage: error.message);
    } catch (_) {
      if (!ref.mounted) return;

      state = const ProductListState(
        errorMessage: AppStrings.productsLoadError,
      );
    }
  }
}
