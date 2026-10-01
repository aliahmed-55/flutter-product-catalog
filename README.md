# Product Catalog

A Flutter product listing and favorites application using the public DummyJSON API. Browse, search, filter by category, load more products, and refresh the current results. Open fresh product details by ID and manage favorites shared across screens. Riverpod manages Product Listing; GetX manages Product Details and Favorites.

## Features

- Product listing with debounced search, category filters, pagination, and pull-to-refresh.
- Product Details fetched by ID, with an image gallery, description, price, discount, rating, stock, brand, and category.
- In-memory favorites synchronized between Product List, Product Details, and Favorites.
- Loading, empty, and error states with retry, including recovery from load-more failures.
- Cached network images with loading/error placeholders and a responsive Material 3 interface.
- A focused unit and widget test suite.

## Tech Stack

Flutter and Dart, `flutter_riverpod`, `get` (GetX), `http`, `cached_network_image`, and the DummyJSON API. Tests use `flutter_test`; static analysis uses `flutter_lints`.

## Setup

Use a Flutter SDK that includes Dart compatible with `^3.12.2`, as required by `pubspec.yaml`. Have Chrome installed for web development, or configure an emulator/connected device and its platform toolchain. Dart is bundled with Flutter.

From the project root:

```sh
flutter pub get
flutter run
```

To select Chrome explicitly:

```sh
flutter run -d chrome
```

The application uses public DummyJSON endpoints. No API key, environment variables, or custom backend setup is required. An internet connection is needed to load products and images.

## Architecture

The project uses practical feature-based MVVM. Screens and shared widgets render state; view models manage requests and interactions; the data layer contains models, the repository, and networking code.

```text
View
  -> ViewModel
  -> ProductRepository (ProductRepositoryImpl)
  -> ProductApiService
  -> ApiClient
  -> DummyJSON API
```

`ProductListNotifier` and `ProductDetailsController` depend on `ProductRepository`. `FavoritesController` manages session-only local state and does not call the data layer. Riverpod providers construct the shared networking dependencies; the Details binding receives that same repository instance.

## Project Structure

```text
lib/
  app/                    Application setup and routes
  core/
    constants/            API endpoints and UI strings
    network/              ApiClient and ApiException
    theme/                Shared Material 3 theme
  data/
    models/
    repositories/
    services/
  features/
    product_list/         View, view model, and listing widgets
    product_details/      View, view model, and route binding
    favorites/            View and shared controller
  shared/widgets/         Cards, favorite button, and status views
  main.dart
test/
  api_client_test.dart
  favorites_controller_test.dart
  product_list_notifier_test.dart
  widget_test.dart
  product_details_test.dart
  support/fake_product_repository.dart
```

## Riverpod

`ProductListNotifier` provides a single listing state for initial loading, products, errors, search, categories, pagination, and refresh.

- `ref.watch()` subscribes to state needed during widget build.
- `ref.read()` invokes actions such as search, category selection, refresh, retry, and load more.
- `ref.listen()` shows a SnackBar for load-more failures while retaining products. In `ProductListScreen`, it resets the attached scroll controller to the top when the search query or selected category changes. In `ProductSearchField`, it synchronizes the text controller when the stored query changes.
- `select()` limits subscriptions: `_ProductResults` watches products/loading/error; `LoadMoreFooter` watches loading-more/has-more/error/refreshing; `CategoryFilter` watches category-related state; `ProductSearchField` watches the query.

Search waits 450 ms after input and ignores stale responses. Search takes precedence over the selected category; clearing it restores that category. Selecting a category clears search.

## GetX

GetX supplies reactive state and dependency injection for Details and Favorites, plus named navigation.

`FavoritesController` is registered once in `main()` with `permanent: true`. Its `RxMap<int, Product>` stores products by ID without duplicates. All three screens retrieve this same controller. `FavoriteButton` uses a small `Obx`, so toggling a heart does not rebuild the entire Product List. The Favorites screen observes only its favorites-dependent content.

`ProductDetailsBinding` uses `Get.lazyPut` to create a route-scoped `ProductDetailsController` for `/products/:id`. Navigation passes only the ID. The controller fetches through the repository in `onInit()`, exposes loading/product/error state and retry, and is disposed when the route is removed. It is not permanent.

## Networking

`package:http/http.dart` is lightweight and sufficient for the application's simple REST requests. HTTP usage is isolated in `ApiClient`, which builds URLs from `ApiEndpoints`, sends GET requests with query parameters, applies a 10-second timeout, validates status codes, decodes JSON, and converts failures into `ApiException`.

`ProductApiService` maps endpoint responses into models. `ProductRepositoryImpl` delegates to the service through the `ProductRepository` interface; widgets do not call HTTP, the client, or the service directly.

Base URL: `https://dummyjson.com`

```
GET /products?limit=10&skip=0
GET /products/search?q=<query>&limit=10&skip=0
GET /products/{id}
GET /products/categories
GET /products/category/{slug}?limit=10&skip=0
```

## Pagination and Refresh

Pages request `limit=10` and track the server's `skip`, `limit`, and `total` to calculate `hasMore`. Scrolling near the bottom or pressing Load more requests the next page. Guards prevent overlapping loads or requests after the end; appended products are deduplicated by ID.

Pull-to-refresh fetches the active search/category source from `skip=0` and replaces the list. The refresh indicator awaits the request. While `isRefreshing` is true, additional refresh calls return the existing pending Future.

## Favorites

Favorites use no server endpoint or local persistence. They remain synchronized throughout the current app session and reset after a full application restart. This assessment uses DummyJSON for catalog data only; no favorites backend is configured.

## Error Handling

Shared views display loading, empty results, and readable errors with Retry. HTTP/API errors, unreachable-server errors, timeouts, malformed JSON, and model-parsing failures receive user-friendly messages rather than stack traces.

Initial product failures use the main error view. Load-more failures keep existing products visible, show a SnackBar, and allow retrying the same page. Refresh failures also retain existing products. `CategoryFilter` shows a separate category Retry action unless the initial product load is loading or has failed with no products. The main product Retry also retries categories when a category error exists.

## Performance

Focused Riverpod subscriptions and `select()` reduce unrelated rebuilds; actions use `ref.read()`. GetX observation stays within the relevant content or button. Product Listing uses lazy `ListView.separated`, Favorites uses `ListView.builder`, and the gallery uses `PageView.builder`. Images use `CachedNetworkImage` with bounded display sizes. Debounced search, stale-response protection, and pagination guards prevent unnecessary or outdated work.

## Testing

The project includes 8 unit tests across 3 files and 3 widget tests across 2 files.

The tests cover:

- API request handling, query parameters, JSON decoding, and HTTP errors
- Favorites add, remove, and toggle behavior
- Product listing pagination, search, category interaction, refresh, and load-more behavior
- Product list loading, success, error, and retry states
- Product Details fetching by ID and favorite synchronization

The tests use mocked HTTP responses and a fake repository, so they do not depend on the live API.

Run the tests with:

```sh
flutter test
flutter analyze
```

## Build

To generate the Android release APK:

```sh
flutter build apk --release
```

After a successful build, the APK is available at `build/app/outputs/flutter-apk/app-release.apk`.

The release APK has been successfully built and tested on multiple Android devices.
