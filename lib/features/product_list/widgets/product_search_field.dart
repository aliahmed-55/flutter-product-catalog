import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_strings.dart';
import '../viewmodel/providers.dart';

class ProductSearchField extends ConsumerStatefulWidget {
  const ProductSearchField({super.key});

  @override
  ConsumerState<ProductSearchField> createState() => _ProductSearchFieldState();
}

class _ProductSearchFieldState extends ConsumerState<ProductSearchField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: ref.read(productListNotifierProvider).searchQuery,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(
      productListNotifierProvider.select((state) => state.searchQuery),
    );
    ref.listen(
      productListNotifierProvider.select((state) => state.searchQuery),
      (previous, next) {
        if (_controller.text == next) return;
        _controller.value = TextEditingValue(
          text: next,
          selection: TextSelection.collapsed(offset: next.length),
        );
      },
    );

    return TextField(
      controller: _controller,
      onChanged: (value) =>
          ref.read(productListNotifierProvider.notifier).search(value),
      decoration: InputDecoration(
        hintText: AppStrings.searchProducts,
        prefixIcon: const Icon(Icons.search),
        suffixIcon: query.isEmpty
            ? null
            : IconButton(
                tooltip: 'Clear search',
                onPressed: () =>
                    ref.read(productListNotifierProvider.notifier).search(''),
                icon: const Icon(Icons.close),
              ),
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
