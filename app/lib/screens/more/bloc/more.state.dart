import 'package:app/data/models/regulated_price.model.dart';

/// Status of the More tab's data loading.
enum MoreStatus { loading, ready, error }

/// State for the More tab.
class MoreState {
  const MoreState({
    required this.status,
    this.latestPrice,
    this.errorMessage,
  });

  const MoreState.loading() : this(status: MoreStatus.loading);

  final MoreStatus status;
  final RegulatedPrice? latestPrice;
  final String? errorMessage;
}
