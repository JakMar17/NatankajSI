import 'dart:developer';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:app/data/models/regulated_price.model.dart';
import 'package:app/data/services/regulated_prices.api_service.dart';
import 'package:app/screens/more/price_history/bloc/price_history.state.dart';

/// Fetches regulated price history for the line chart screen.
class PriceHistoryCubit extends Cubit<PriceHistoryState> {
  PriceHistoryCubit({
    required RegulatedPricesApiService regulatedPricesApiService,
  })  : _service = regulatedPricesApiService,
        super(_initialState());

  final RegulatedPricesApiService _service;

  static PriceHistoryState _initialState() {
    final (from, to) = _rangeForPeriod(PeriodType.year);
    return PriceHistoryState(
      status: PriceHistoryStatus.loading,
      period: PeriodType.year,
      fromDate: from,
      toDate: to,
      fuelView: FuelView.both,
    );
  }

  Future<void> load() async {
    emit(state.copyWith(status: PriceHistoryStatus.loading));
    try {
      final fromDate =
          state.period == PeriodType.all ? null : state.fromDate;
      final toDate =
          state.period == PeriodType.all ? null : state.toDate;
      final raw = await _service.list(fromDate: fromDate, toDate: toDate);
      final sorted = [...raw]
        ..sort((a, b) => a.validFrom.compareTo(b.validFrom));
      final filled = _forwardFill(sorted, state.toDate);
      emit(state.copyWith(
        status: PriceHistoryStatus.ready,
        prices: filled,
        touchedX: null,
      ));
    } on Exception catch (e) {
      log('PriceHistoryCubit.load failed: $e');
      emit(state.copyWith(
        status: PriceHistoryStatus.error,
        errorMessage: 'Could not load price history.',
      ));
    }
  }

  void selectPeriod(PeriodType period) {
    final (from, to) = _rangeForPeriod(period);
    emit(state.copyWith(period: period, fromDate: from, toDate: to));
    load();
  }

  void selectFuel(FuelView fuelView) =>
      emit(state.copyWith(fuelView: fuelView));

  void setTouchedX(double x) {
    if (state.touchedX == x) return;
    emit(state.copyWith(touchedX: x));
  }

  void goPrevious() {
    final (from, to) = _shift(state.fromDate, state.toDate, forward: false);
    emit(state.copyWith(fromDate: from, toDate: to));
    load();
  }

  void goNext() {
    if (!state.canGoNext) return;
    final (from, to) = _shift(state.fromDate, state.toDate, forward: true);
    emit(state.copyWith(fromDate: from, toDate: to));
    load();
  }

  /// Fills every missing day between API entries using each entry's own
  /// price (null entries create a gap — they are not forward-filled over).
  /// Extends from the last entry up to [endDate], capped at today.
  static List<RegulatedPrice> _forwardFill(
    List<RegulatedPrice> sorted,
    DateTime endDate,
  ) {
    if (sorted.isEmpty) return sorted;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final effectiveEnd = endDate.isAfter(today) ? today : endDate;

    final result = <RegulatedPrice>[];

    for (int i = 0; i < sorted.length; i++) {
      final curr = sorted[i];
      // Don't forward-fill through null entries — null means no regulated price.
      final fillPetrol = curr.petrolPrice;
      final fillDiesel = curr.dieselPrice;
      result.add(curr);

      final nextDate = (i + 1 < sorted.length)
          ? sorted[i + 1].validFrom
          : effectiveEnd.add(const Duration(days: 1));

      var d = DateTime(
        curr.validFrom.year,
        curr.validFrom.month,
        curr.validFrom.day + 1,
      );
      while (d.isBefore(nextDate) && !d.isAfter(effectiveEnd)) {
        result.add(RegulatedPrice(
          pk: curr.pk,
          validFrom: d,
          petrolPrice: fillPetrol,
          dieselPrice: fillDiesel,
        ));
        d = d.add(const Duration(days: 1));
      }
    }
    return result;
  }

  static (DateTime, DateTime) _rangeForPeriod(PeriodType period) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return switch (period) {
      PeriodType.year => (DateTime(now.year), today),
      PeriodType.all => (DateTime(2020), today),
    };
  }

  static (DateTime, DateTime) _shift(
    DateTime from,
    DateTime to, {
    required bool forward,
  }) {
    final d = forward ? 1 : -1;
    return (DateTime(from.year + d), DateTime(to.year + d, 12, 31));
  }
}
