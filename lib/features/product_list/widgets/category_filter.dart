import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_strings.dart';
import '../viewmodel/providers.dart';

class CategoryFilter extends ConsumerWidget {
  const CategoryFilter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (
      categories,
      selectedSlug,
      searching,
      loading,
      error,
      primaryFailure,
    ) = ref.watch(
      productListNotifierProvider.select(
        (state) => (
          state.categories,
          state.selectedCategory?.slug,
          state.searchQuery.trim().isNotEmpty,
          state.isLoadingCategories,
          state.categoryError,
          state.products.isEmpty &&
              (state.isLoading || state.errorMessage != null),
        ),
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              ChoiceChip(
                label: const Text(AppStrings.allCategories),
                selected: !searching && selectedSlug == null,
                onSelected: (_) => ref
                    .read(productListNotifierProvider.notifier)
                    .selectCategory(null),
              ),
              for (final category in categories) ...[
                const SizedBox(width: 8),
                ChoiceChip(
                  label: Text(category.name),
                  selected: !searching && selectedSlug == category.slug,
                  onSelected: (_) => ref
                      .read(productListNotifierProvider.notifier)
                      .selectCategory(category),
                ),
              ],
            ],
          ),
        ),
        if (loading) const LinearProgressIndicator(),
        if (error != null && !primaryFailure)
          Row(
            children: [
              Expanded(
                child: Text(
                  error,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              TextButton(
                onPressed: () => ref
                    .read(productListNotifierProvider.notifier)
                    .loadCategories(),
                child: const Text(AppStrings.retry),
              ),
            ],
          ),
      ],
    );
  }
}
