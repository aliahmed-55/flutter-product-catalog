import 'package:get/get.dart';

import '../../../data/repositories/product_repository.dart';
import '../viewmodel/product_details_controller.dart';

class ProductDetailsBinding extends Bindings {
  ProductDetailsBinding(this.repository);

  final ProductRepository repository;

  @override
  void dependencies() {
    final id = int.tryParse(Get.parameters['id'] ?? '') ?? 0;
    Get.lazyPut<ProductDetailsController>(
      () => ProductDetailsController(repository: repository, productId: id),
    );
  }
}
