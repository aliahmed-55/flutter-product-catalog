import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/network/api_exception.dart';
import '../../../data/models/category.dart';
import '../../../data/models/product.dart';
import '../../../data/models/product_page.dart';
import 'product_list_state.dart';
import 'providers.dart';

class ProductListNotifier extends Notifier<ProductListState> {
  Timer? _debounce;
  int _requestId = 0;
  Future<void>? _refreshFuture;

  @override
  ProductListState build() {
    ref.onDispose(() {
      _debounce?.cancel();
      _requestId++;
    });
    Future.microtask(() {
      if (!ref.mounted) return;
      unawaited(_reload());
      unawaited(loadCategories());
    });
    return const ProductListState(isLoading: true);
  }

  Future<void> loadCategories() async {
    if (state.isLoadingCategories) return;
    state = state.copyWith(isLoadingCategories: true, clearCategoryError: true);
    try {
      final categories = await ref
          .read(productRepositoryProvider)
          .getCategories();
      if (!ref.mounted) return;
      state = state.copyWith(
        categories: categories,
        isLoadingCategories: false,
      );
    } catch (error) {
      if (!ref.mounted) return;
      state = state.copyWith(
        isLoadingCategories: false,
        categoryError: _message(error, AppStrings.categoriesLoadError),
      );
    }
  }

  void search(String query) {
    if (query == state.searchQuery) return;
    _debounce?.cancel();
    _requestId++;
    state = state.copyWith(searchQuery: query);
    _resetPage();
    if (query.trim().isEmpty) {
      unawaited(_reload());
    } else {
      _debounce = Timer(const Duration(milliseconds: 450), () {
        _debounce = null;
        unawaited(_reload());
      });
    }
  }

  Future<void> selectCategory(Category? category) async {
    if (state.selectedCategory?.slug == category?.slug &&
        state.searchQuery.isEmpty) {
      return;
    }
    state = state.copyWith(
      selectedCategory: category,
      clearCategory: category == null,
      searchQuery: '',
    );
    await _reload();
  }

  Future<void> loadProducts() async {
    if (state.isLoading || state.isRefreshing) return;
    if (state.categoryError != null) unawaited(loadCategories());
    await _reload();
  }

  Future<void> refresh() {
    final pending = _refreshFuture;
    if (state.isRefreshing && pending != null) return pending;
    if (state.categoryError != null) unawaited(loadCategories());
    final request = _reload(refresh: true);
    _refreshFuture = request;
    return request;
  }

  void _resetPage({bool refresh = false}) {
    state = state.copyWith(
      products: refresh ? state.products : const [],
      isLoading: !refresh,
      isRefreshing: refresh,
      isLoadingMore: false,
      clearError: true,
      clearLoadMoreError: true,
      skip: 0,
      limit: 10,
      total: 0,
      hasMore: false,
    );
  }

  Future<void> _reload({bool refresh = false}) async {
    if (!ref.mounted) return;
    _debounce?.cancel();
    _debounce = null;
    final requestId = ++_requestId;
    _resetPage(refresh: refresh);
    try {
      final page = await _getPage(0);
      if (!ref.mounted || requestId != _requestId) return;
      state = state.copyWith(
        products: page.products,
        isLoading: false,
        isRefreshing: false,
        skip: page.skip,
        limit: page.limit,
        total: page.total,
        hasMore: _hasMore(page),
      );
    } catch (error) {
      if (!ref.mounted || requestId != _requestId) return;
      state = state.copyWith(
        isLoading: false,
        isRefreshing: false,
        errorMessage: _message(error, AppStrings.productsLoadError),
      );
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading ||
        state.isRefreshing ||
        state.isLoadingMore ||
        !state.hasMore ||
        state.products.isEmpty) {
      return;
    }
    final requestId = _requestId;
    final nextSkip = state.skip + state.limit;
    state = state.copyWith(isLoadingMore: true, clearLoadMoreError: true);
    try {
      final page = await _getPage(nextSkip);
      if (!ref.mounted || requestId != _requestId) return;
      final productsById = <int, Product>{
        for (final product in state.products) product.id: product,
        for (final product in page.products) product.id: product,
      };
      state = state.copyWith(
        products: List<Product>.unmodifiable(productsById.values),
        isLoadingMore: false,
        skip: page.skip,
        limit: page.limit,
        total: page.total,
        hasMore: page.skip >= nextSkip && _hasMore(page),
      );
    } catch (error) {
      if (!ref.mounted || requestId != _requestId) return;
      state = state.copyWith(
        isLoadingMore: false,
        loadMoreError: _message(error, AppStrings.loadMoreError),
      );
    }
  }

  Future<ProductPage> _getPage(int skip) {
    final repository = ref.read(productRepositoryProvider);
    final query = state.searchQuery.trim();
    if (query.isNotEmpty) {
      return repository.searchProducts(query: query, limit: 10, skip: skip);
    }
    final category = state.selectedCategory;
    if (category != null) {
      return repository.getProductsByCategory(
        slug: category.slug,
        limit: 10,
        skip: skip,
      );
    }
    return repository.getProducts(limit: 10, skip: skip);
  }

  bool _hasMore(ProductPage page) =>
      page.products.isNotEmpty &&
      page.limit > 0 &&
      page.skip + page.limit < page.total;

  String _message(Object error, String fallback) =>
      error is ApiException ? error.message : fallback;
}
