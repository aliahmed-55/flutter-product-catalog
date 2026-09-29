import 'package:get/get.dart';

import '../view/app_shell_screen.dart';
import 'app_routes.dart';

abstract final class AppPages {
  static final pages = <GetPage<void>>[
    GetPage<void>(name: AppRoutes.home, page: () => const AppShellScreen()),
  ];
}
