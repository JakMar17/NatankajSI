import 'package:app/data/models/app_boot_data.model.dart';

/// Holds pre-fetched startup data for sharing across feature cubits.
///
/// Set once by [StartupGateCubit] before any feature tab is shown.
/// Feature cubits check [data] first; if non-null they skip redundant
/// API calls and use the cached values instead.
class AppBootRepository {
  AppBootData? data;
}
