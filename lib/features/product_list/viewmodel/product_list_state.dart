import '../../../data/models/category.dart';
import '../../../data/models/product.dart';

class ProductListState {
  const ProductListState({
    this.products = const [],
    this.categories = const [],
    this.isLoading = false,
    this.isRefreshing = false,
    this.isLoadingMore = false,
    this.isLoadingCategories = false,
    this.errorMessage,
    this.loadMoreError,
    this.categoryError,
    this.searchQuery = '',
    this.selectedCategory,
    this.skip = 0,
    this.limit = 10,
    this.total = 0,
    this.hasMore = false,
  });

  final List<Product> products;
  final List<Category> categories;
  final bool isLoading;
  final bool isRefreshing;
  final bool isLoadingMore;
  final bool isLoadingCategories;
  final String? errorMessage;
  final String? loadMoreError;
  final String? categoryError;
  final String searchQuery;
  final Category? selectedCategory;
  final int skip;
  final int limit;
  final int total;
  final bool hasMore;

  bool get isEmpty => !isLoading && errorMessage == null && products.isEmpty;

  ProductListState copyWith({
    List<Product>? products,
    List<Category>? categories,
    bool? isLoading,
    bool? isRefreshing,
    bool? isLoadingMore,
    bool? isLoadingCategories,
    String? errorMessage,
    bool clearError = false,
    String? loadMoreError,
    bool clearLoadMoreError = false,
    String? categoryError,
    bool clearCategoryError = false,
    String? searchQuery,
    Category? selectedCategory,
    bool clearCategory = false,
    int? skip,
    int? limit,
    int? total,
    bool? hasMore,
  }) {
    return ProductListState(
      products: products ?? this.products,
      categories: categories ?? this.categories,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isLoadingCategories: isLoadingCategories ?? this.isLoadingCategories,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      loadMoreError: clearLoadMoreError
          ? null
          : loadMoreError ?? this.loadMoreError,
      categoryError: clearCategoryError
          ? null
          : categoryError ?? this.categoryError,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCategory: clearCategory
          ? null
          : selectedCategory ?? this.selectedCategory,
      skip: skip ?? this.skip,
      limit: limit ?? this.limit,
      total: total ?? this.total,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}
