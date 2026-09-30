import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:product_catalog/core/network/api_exception.dart';
import 'package:product_catalog/data/models/product_page.dart';
import 'package:product_catalog/features/product_list/viewmodel/product_list_notifier.dart';
import 'package:product_catalog/features/product_list/viewmodel/providers.dart';

import 'support/fake_product_repository.dart';

void main() {
  late FakeProductRepository repository;
  late ProviderContainer container;
  late ProductListNotifier notifier;

  setUp(() async {
    repository = FakeProductRepository(() async => productPage(10, total: 25));
    container = ProviderContainer(
      overrides: [productRepositoryProvider.overrideWithValue(repository)],
    );
    container.listen(productListNotifierProvider, (_, _) {});
    notifier = container.read(productListNotifierProvider.notifier);
    await Future<void>.delayed(Duration.zero);
  });

  tearDown(() => container.dispose());

  test(
    'Pages use server offsets, reject duplicate calls, deduplicate IDs and stop',
    () async {
      expect(repository.calls, 1);
      expect(repository.categoryCalls, 1);
      final pending = Completer<ProductPage>();
      repository.onPage = (_, _) => pending.future;
      final request = notifier.loadMore();
      await notifier.loadMore();
      expect(repository.calls, 2);
      pending.complete(
        productPage(
          10,
          skip: 10,
          total: 25,
          ids: List.generate(10, (i) => i + 9),
        ),
      );
      await request;
      expect(container.read(productListNotifierProvider).products.length, 18);
      repository.onPage = (_, skip) async =>
          productPage(5, skip: skip, total: 25);
      await notifier.loadMore();
      expect(repository.requests.map((request) => request.skip), [0, 10, 20]);
      expect(container.read(productListNotifierProvider).hasMore, isFalse);
      await notifier.loadMore();
      expect(repository.calls, 3);
    },
  );

  test(
    'Debounce sends only the final query and ignores an older search response',
    () async {
      final old = Completer<ProductPage>();
      repository.onPage = (source, skip) => source == 'search:phone'
          ? old.future
          : Future.value(productPage(1, ids: [99]));
      notifier.search('p');
      notifier.search('ph');
      notifier.search('phone');
      await Future<void>.delayed(const Duration(milliseconds: 500));
      expect(repository.requests.map((request) => request.source), [
        'all',
        'search:phone',
      ]);
      notifier.search('laptop');
      old.complete(productPage(1, ids: [55]));
      await Future<void>.delayed(Duration.zero);
      expect(container.read(productListNotifierProvider).products, isEmpty);
      await Future<void>.delayed(const Duration(milliseconds: 500));
      expect(
        container.read(productListNotifierProvider).products.single.id,
        99,
      );
    },
  );

  test(
    'Search overrides category, clearing restores it, selection clears search',
    () async {
      await notifier.selectCategory(beauty);
      notifier.search('phone');
      await Future<void>.delayed(const Duration(milliseconds: 500));
      await notifier.loadMore();
      expect(repository.requests.last, (source: 'search:phone', skip: 10));
      notifier.search('');
      await Future<void>.delayed(Duration.zero);
      expect(repository.requests.last, (source: 'category:beauty', skip: 0));
      notifier.search('pending');
      await notifier.selectCategory(groceries);
      expect(container.read(productListNotifierProvider).searchQuery, '');
      expect(repository.requests.last, (source: 'category:groceries', skip: 0));
      await notifier.loadMore();
      expect(repository.requests.last, (
        source: 'category:groceries',
        skip: 10,
      ));
      notifier.search('pending');
      await notifier.selectCategory(null);
      await Future<void>.delayed(const Duration(milliseconds: 500));
      expect(repository.requests.last, (source: 'all', skip: 0));
      expect(
        container.read(productListNotifierProvider).selectedCategory,
        isNull,
      );
    },
  );

  test(
    'Refresh supersedes load more, keeps source and replaces products',
    () async {
      await notifier.selectCategory(groceries);
      final oldPage = Completer<ProductPage>();
      repository.onPage = (_, skip) => skip == 10
          ? oldPage.future
          : Future.value(productPage(2, ids: [70, 71]));
      final loadingMore = notifier.loadMore();
      await notifier.refresh();
      oldPage.complete(productPage(10, skip: 10, total: 25));
      await loadingMore;
      expect(
        container.read(productListNotifierProvider).products.map((p) => p.id),
        [70, 71],
      );
      expect(repository.requests.last, (source: 'category:groceries', skip: 0));
      expect(
        container.read(productListNotifierProvider).isLoadingMore,
        isFalse,
      );
    },
  );

  test(
    'Load-more failure preserves products and retries the same offset',
    () async {
      repository.onPage = (_, _) async =>
          throw const ApiException('Connection lost');
      await notifier.loadMore();
      var state = container.read(productListNotifierProvider);
      expect(state.products.length, 10);
      expect(state.errorMessage, isNull);
      expect(state.loadMoreError, 'Connection lost');
      expect(state.isLoadingMore, isFalse);
      repository.onPage = (_, skip) async =>
          productPage(10, skip: skip, total: 25);
      await notifier.loadMore();
      state = container.read(productListNotifierProvider);
      expect(state.products.length, 20);
      expect(state.loadMoreError, isNull);
      expect(repository.requests.map((request) => request.skip), [0, 10, 10]);
    },
  );
}
