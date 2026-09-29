import '../../../data/models/product.dart';

class ProductListState {
  const ProductListState({
    this.products = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  final List<Product> products;
  final bool isLoading;
  final String? errorMessage;

  bool get isEmpty => !isLoading && errorMessage == null && products.isEmpty;
}
