import 'package:app/data/models/app_boot_data.model.dart';
import 'package:app/data/models/latest_price_entry.model.dart';

/// Holds pre-fetched startup data for sharing across feature cubits.
///
/// Set once by [StartupGateCubit] before any feature tab is shown.
/// Feature cubits check [data] first; if non-null they skip redundant
/// API calls and use the cached values instead.
class AppBootRepository {
  AppBootData? data;

  /// Future that resolves to the latest-prices map once the background fetch
  /// started by [StartupGateCubit] completes.
  ///
  /// Feature screens await this when they need per-station price data.
  /// Always resolves — errors are caught and return an empty map.
  Future<Map<int, List<LatestPriceEntry>>>? latestPricesFuture;
}
