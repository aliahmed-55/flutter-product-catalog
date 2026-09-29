abstract final class AppRoutes {
  static const home = '/';
  static const productDetails = '/products/:id';

  static String product(int id) => '/products/$id';
}
