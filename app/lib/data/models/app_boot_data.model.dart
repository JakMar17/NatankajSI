import 'package:latlong2/latlong.dart';

import 'package:app/data/models/franchise.model.dart';
import 'package:app/data/models/fuel_type.model.dart';
import 'package:app/data/models/regulated_price.model.dart';
import 'package:app/data/models/station_with_prices.model.dart';

/// Pre-fetched app startup data shared across feature cubits.
///
/// Populated once by [StartupGateCubit] before the app shell is shown, so
/// all feature cubits can consume it without re-fetching or racing on
/// location-permission requests.
class AppBootData {
  const AppBootData({
    required this.stations,
    required this.franchises,
    required this.fuels,
    required this.userLocation,
    required this.latestRegulatedPrice,
  });

  final List<StationWithPrices> stations;
  final List<Franchise> franchises;
  final List<FuelType> fuels;
  final LatLng? userLocation;
  final RegulatedPrice? latestRegulatedPrice;
}
