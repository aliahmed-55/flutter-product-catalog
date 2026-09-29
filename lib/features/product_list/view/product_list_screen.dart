import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../shared/widgets/empty_view.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../../shared/widgets/product_card.dart';
import '../viewmodel/providers.dart';
import '../widgets/category_filter.dart';
import '../widgets/load_more_footer.dart';
import '../widgets/product_search_field.dart';

class ProductListScreen extends ConsumerStatefulWidget {
  const ProductListScreen({super.key});

  @override
  ConsumerState<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends ConsumerState<ProductListScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollController.hasClients || _scrollController.offset <= 0) return;
    if (_scrollController.position.extentAfter < 300 &&
        ref.read(productListNotifierProvider).loadMoreError == null) {
      ref.read(productListNotifierProvider.notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(
      productListNotifierProvider.select((state) => state.loadMoreError),
      (previous, next) {
        if (next == null || next == previous) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(next)));
      },
    );
    ref.listen(
      productListNotifierProvider.select(
        (state) => (state.searchQuery, state.selectedCategory?.slug),
      ),
      (previous, next) {
        if (_scrollController.hasClients) _scrollController.jumpTo(0);
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.appName),
        actions: [
          IconButton(
            tooltip: 'Open favorites',
            icon: const Icon(Icons.favorite_outline),
            onPressed: () => Get.toNamed<void>(AppRoutes.favorites),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: ProductSearchField(),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: CategoryFilter(),
                ),
                Expanded(child: _ProductResults(controller: _scrollController)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProductResults extends ConsumerWidget {
  const _ProductResults({required this.controller});

  final ScrollController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (products, loading, error) = ref.watch(
      productListNotifierProvider.select(
        (state) => (state.products, state.isLoading, state.errorMessage),
      ),
    );
    if (loading) return const LoadingView();

    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(
        dragDevices: {
          ...ScrollConfiguration.of(context).dragDevices,
          PointerDeviceKind.mouse,
        },
      ),
      child: RefreshIndicator(
        onRefresh: () =>
            ref.read(productListNotifierProvider.notifier).refresh(),
        child: products.isEmpty
            ? LayoutBuilder(
                builder: (context, constraints) {
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(
                        height: constraints.maxHeight,
                        child: error != null
                            ? ErrorView(
                                message: error,
                                onRetry: () => ref
                                    .read(productListNotifierProvider.notifier)
                                    .loadProducts(),
                              )
                            : const EmptyView(message: AppStrings.noProducts),
                      ),
                    ],
                  );
                },
              )
            : Column(
                children: [
                  if (error != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Expanded(child: Text(error)),
                          TextButton(
                            onPressed: () => ref
                                .read(productListNotifierProvider.notifier)
                                .refresh(),
                            child: const Text(AppStrings.retry),
                          ),
                        ],
                      ),
                    ),
                  Expanded(
                    child: ListView.separated(
                      key: const ValueKey('product-list'),
                      controller: controller,
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      itemCount: products.length + 1,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        if (index == products.length) {
                          return const LoadMoreFooter();
                        }
                        final product = products[index];
                        return ProductCard(
                          key: ValueKey(product.id),
                          product: product,
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
