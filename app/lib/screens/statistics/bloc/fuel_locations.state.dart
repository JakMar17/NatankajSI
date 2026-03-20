/// Loading state for fuel location list screen.
enum FuelLocationsStatus { loading, ready, error }

/// Supported ordering options for fuel location list.
enum FuelLocationsOrderBy { distance, price }

/// One station entry in the fuel locations list.
class FuelLocationItem {
  const FuelLocationItem({
    required this.stationPk,
    required this.stationName,
    required this.stationAddress,
    required this.franchiseName,
    required this.openHours,
    required this.price,
    required this.distanceKm,
  });

  final int stationPk;
  final String stationName;
  final String? stationAddress;
  final String? franchiseName;
  final String? openHours;
  final double price;
  final double? distanceKm;
}

/// UI state for the fuel locations list screen.
class FuelLocationsState {
  const FuelLocationsState({
    required this.status,
    required this.errorMessage,
    required this.searchQuery,
    required this.orderBy,
    required this.isAscending,
    required this.allItems,
    required this.visibleItems,
  });

  factory FuelLocationsState.initial() {
    return const FuelLocationsState(
      status: FuelLocationsStatus.loading,
      errorMessage: null,
      searchQuery: '',
      orderBy: FuelLocationsOrderBy.distance,
      isAscending: true,
      allItems: <FuelLocationItem>[],
      visibleItems: <FuelLocationItem>[],
    );
  }

  final FuelLocationsStatus status;
  final String? errorMessage;
  final String searchQuery;
  final FuelLocationsOrderBy orderBy;
  final bool isAscending;
  final List<FuelLocationItem> allItems;
  final List<FuelLocationItem> visibleItems;

  FuelLocationsState copyWith({
    FuelLocationsStatus? status,
    String? errorMessage,
    bool clearErrorMessage = false,
    String? searchQuery,
    FuelLocationsOrderBy? orderBy,
    bool? isAscending,
    List<FuelLocationItem>? allItems,
    List<FuelLocationItem>? visibleItems,
  }) {
    return FuelLocationsState(
      status: status ?? this.status,
      errorMessage: clearErrorMessage
          ? null
          : (errorMessage ?? this.errorMessage),
      searchQuery: searchQuery ?? this.searchQuery,
      orderBy: orderBy ?? this.orderBy,
      isAscending: isAscending ?? this.isAscending,
      allItems: allItems ?? this.allItems,
      visibleItems: visibleItems ?? this.visibleItems,
    );
  }
}
