import 'dart:developer';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:app/data/services/regulated_prices.api_service.dart';
import 'package:app/screens/more/bloc/more.state.dart';

/// Loads the latest regulated price for the More tab header card.
class MoreCubit extends Cubit<MoreState> {
  MoreCubit({
    required RegulatedPricesApiService regulatedPricesApiService,
  })  : _service = regulatedPricesApiService,
        super(const MoreState.loading());

  final RegulatedPricesApiService _service;

  Future<void> load() async {
    emit(const MoreState.loading());
    try {
      final latest = await _service.getLatest();
      emit(MoreState(status: MoreStatus.ready, latestPrice: latest));
    } on Exception catch (e) {
      log('MoreCubit.load failed: $e');
      emit(
        const MoreState(
          status: MoreStatus.error,
          errorMessage: 'Could not load regulated prices.',
        ),
      );
    }
  }
}
