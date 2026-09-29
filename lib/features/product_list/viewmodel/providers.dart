import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../data/repositories/product_repository.dart';
import '../../../data/repositories/product_repository_impl.dart';
import '../../../data/services/product_api_service.dart';
import 'product_list_notifier.dart';
import 'product_list_state.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  final client = ApiClient();
  ref.onDispose(client.close);
  return client;
});

final productApiServiceProvider = Provider<ProductApiService>((ref) {
  return ProductApiService(ref.watch(apiClientProvider));
});

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepositoryImpl(ref.watch(productApiServiceProvider));
});

final productListNotifierProvider =
    NotifierProvider.autoDispose<ProductListNotifier, ProductListState>(
      ProductListNotifier.new,
    );
