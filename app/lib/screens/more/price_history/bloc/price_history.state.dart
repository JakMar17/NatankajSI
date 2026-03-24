import 'package:app/data/models/regulated_price.model.dart';

/// Status of the price history data loading.
enum PriceHistoryStatus { loading, ready, error }

/// The active time window granularity.
enum PeriodType { year, all }

/// Which fuel(s) are shown in the chart.
enum FuelView { petrol, diesel, both }

/// State for the regulated price history chart screen.
class PriceHistoryState {
  const PriceHistoryState({
    required this.status,
    required this.period,
    required this.fromDate,
    required this.toDate,
    required this.fuelView,
    this.prices = const [],
    this.errorMessage,
    this.touchedX,
  });

  final PriceHistoryStatus status;
  final PeriodType period;
  final DateTime fromDate;
  final DateTime toDate;
  final FuelView fuelView;
  final List<RegulatedPrice> prices;
  final String? errorMessage;
  final double? touchedX;

  /// Whether the range can be advanced forward (year period only).
  bool get canGoNext {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    return toDate.isBefore(todayDate);
  }

  static const _absent = Object();

  PriceHistoryState copyWith({
    PriceHistoryStatus? status,
    PeriodType? period,
    DateTime? fromDate,
    DateTime? toDate,
    FuelView? fuelView,
    List<RegulatedPrice>? prices,
    String? errorMessage,
    Object? touchedX = _absent,
  }) =>
      PriceHistoryState(
        status: status ?? this.status,
        period: period ?? this.period,
        fromDate: fromDate ?? this.fromDate,
        toDate: toDate ?? this.toDate,
        fuelView: fuelView ?? this.fuelView,
        prices: prices ?? this.prices,
        errorMessage: errorMessage ?? this.errorMessage,
        touchedX: identical(touchedX, _absent)
            ? this.touchedX
            : touchedX as double?,
      );
}
