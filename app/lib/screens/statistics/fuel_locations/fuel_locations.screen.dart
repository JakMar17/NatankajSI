import 'dart:ui';

import 'package:app/data/data.dart';
import 'package:app/extensions/string.extension.dart';
import 'package:app/screens/statistics/bloc/fuel_locations.cubit.dart';
import 'package:app/screens/statistics/bloc/fuel_locations.state.dart';
import 'package:app/screens/statistics/bloc/statistics.state.dart';
import 'package:app/styles/styles.dart';
import 'package:app/widgets/base/base.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'views/_fuel_locations_loaded.view.dart';
part 'views/_fuel_locations_statistics_tab.view.dart';
part 'widgets/_fuel_location_card.widget.dart';
part 'widgets/_fuel_locations_header.widget.dart';
part 'widgets/_fuel_search.widget.dart';

class FuelLocationsScreen extends StatelessWidget {
  final String fuelCode;
  final String fuelLabel;
  final ValueChanged<int> onStationPressed;

  const FuelLocationsScreen({
    super.key,
    required this.fuelCode,
    required this.fuelLabel,
    required this.onStationPressed,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider<FuelLocationsCubit>(
      create: (context) => FuelLocationsCubit(
        stationsApiService: context.read<StationsApiService>(),
        appBootRepository: context.read<AppBootRepository>(),
      )..load(fuelCode: fuelCode, fuelLabel: fuelLabel),
      child: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppGradients.appBackground),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: BlocBuilder<FuelLocationsCubit, FuelLocationsState>(
              builder: (context, state) => switch (state.status) {
                .loading => const Center(child: CircularProgressIndicator()),
                .error => _buildErrorState(
                  context,
                  message: state.errorMessage ?? 'Could not load fuel locations.',
                  onRetry: () => context
                      .read<FuelLocationsCubit>()
                      .load(fuelCode: fuelCode, fuelLabel: fuelLabel),
                ),
                .ready => _FuelLocationsLoadedView(
                  fuelCode: fuelCode,
                  fuelLabel: fuelLabel,
                  onStationPressed: onStationPressed,
                ),
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, {required String message, required VoidCallback onRetry}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
