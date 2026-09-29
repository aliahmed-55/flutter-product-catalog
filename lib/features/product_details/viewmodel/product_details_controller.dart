import 'package:get/get.dart';

import '../../../core/network/api_exception.dart';
import '../../../data/models/product.dart';
import '../../../data/repositories/product_repository.dart';

class ProductDetailsController extends GetxController {
  ProductDetailsController({required this.repository, required this.productId});

  final ProductRepository repository;
  final int productId;
  final isLoading = false.obs;
  final product = Rxn<Product>();
  final errorMessage = RxnString();

  @override
  void onInit() {
    super.onInit();
    retry();
  }

  Future<void> retry() async {
    if (isLoading.value || isClosed) return;
    errorMessage.value = null;
    if (productId <= 0) {
      errorMessage.value = 'This product link is invalid.';
      return;
    }
    isLoading.value = true;
    try {
      final result = await repository.getProduct(productId);
      if (!isClosed) product.value = result;
    } on ApiException catch (error) {
      if (!isClosed) errorMessage.value = error.message;
    } catch (_) {
      if (!isClosed) {
        errorMessage.value = 'Unable to load this product. Please try again.';
      }
    } finally {
      if (!isClosed) isLoading.value = false;
    }
  }
}
