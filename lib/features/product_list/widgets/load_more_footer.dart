import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_strings.dart';
import '../viewmodel/providers.dart';

class LoadMoreFooter extends ConsumerWidget {
  const LoadMoreFooter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (loading, hasMore, error, refreshing) = ref.watch(
      productListNotifierProvider.select(
        (state) => (
          state.isLoadingMore,
          state.hasMore,
          state.loadMoreError,
          state.isRefreshing,
        ),
      ),
    );
    if (loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    if (!hasMore || refreshing) return const SizedBox.shrink();
    return Center(
      child: TextButton(
        onPressed: () =>
            ref.read(productListNotifierProvider.notifier).loadMore(),
        child: Text(error == null ? AppStrings.loadMore : AppStrings.retry),
      ),
    );
  }
}
