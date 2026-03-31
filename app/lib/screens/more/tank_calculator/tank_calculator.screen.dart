import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import 'package:app/data/data.dart';
import 'package:app/screens/more/tank_calculator/bloc/tank_calculator.cubit.dart';
import 'package:app/screens/more/tank_calculator/bloc/tank_calculator.state.dart';
import 'package:app/screens/more/tank_calculator/widgets/_price_range_chart.widget.dart';
import 'package:app/styles/styles.dart';

part 'widgets/_station_card.widget.dart';
part 'widgets/_capacity_dialog.widget.dart';
part 'widgets/_fuel_selector_sheet.widget.dart';
part 'widgets/_fuel_chip.widget.dart';
part 'widgets/_tank_cost_history_inline.widget.dart';

/// Calculates the full cost of a tank fill across nearby stations.
class TankCalculatorScreen extends StatelessWidget {
  const TankCalculatorScreen({super.key, required this.onStationPressed});

  final void Function(int stationPk) onStationPressed;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<TankCalculatorCubit>(
      create: (context) => TankCalculatorCubit(
        stationsApiService: context.read<StationsApiService>(),
        appBootRepository: context.read<AppBootRepository>(),
        regulatedPricesApiService: context.read<RegulatedPricesApiService>(),
      )..load(),
      child: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppGradients.appBackground),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: _buildAppBar(),
          body: BlocBuilder<TankCalculatorCubit, TankCalculatorState>(
            builder: (context, state) => switch (state.status) {
              .loading => const Center(child: CircularProgressIndicator()),
              .error => _buildErrorView(
                context,
                message: state.errorMessage,
                onRetry: context.read<TankCalculatorCubit>().load,
              ),
              .ready => _ReadyBody(
                state: state,
                onStationPressed: onStationPressed,
              ),
            },
          ),
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: const Text('Tank Calculator'),
    );
  }

  Widget _buildErrorView(
    BuildContext context, {
    String? message,
    required VoidCallback onRetry,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message ?? 'Error loading data.',
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

class _ReadyBody extends StatelessWidget {
  const _ReadyBody({required this.state, required this.onStationPressed});

  final TankCalculatorState state;
  final void Function(int stationPk) onStationPressed;

  @override
  Widget build(BuildContext context) {
    final cheapest = state.cheapestAll;
    final priciest = state.mostExpensiveAll;
    final shownPks = <int>{};

    List<Widget> stationCards() {
      final cards = <Widget>[];

      void addCard({
        required String label,
        required StationSummary station,
        bool highlight = false,
        bool dimmed = false,
      }) {
        if (shownPks.contains(station.pk)) return;
        shownPks.add(station.pk);
        if (cards.isNotEmpty) cards.add(const SizedBox(height: 10));
        cards.add(
          _StationCard(
            label: label,
            station: station,
            capacityLiters: state.capacityLiters,
            fuelCode: state.fuelCode ?? '',
            highlight: highlight,
            dimmed: dimmed,
            onTap: () {
              Navigator.of(context).pop();
              onStationPressed(station.pk);
            },
          ),
        );
      }

      if (state.closestStation != null) {
        addCard(label: 'CLOSEST TO YOU', station: state.closestStation!);
      }
      if (state.cheapestNearby != null) {
        addCard(
          label: 'CHEAPEST WITHIN 30 KM',
          station: state.cheapestNearby!,
          highlight: true,
        );
      }
      if (state.mostExpensiveNearby != null) {
        addCard(
          label: 'MOST EXPENSIVE WITHIN 30 KM',
          station: state.mostExpensiveNearby!,
          dimmed: true,
        );
      }
      if (!state.hasLocation) {
        cards.add(_buildLocationBanner(context));
        if (cheapest != null) cards.add(const SizedBox(height: 10));
      }
      if (cheapest != null) {
        addCard(
          label: 'CHEAPEST OVERALL',
          station: cheapest,
          highlight: !state.hasLocation,
        );
      }
      if (priciest != null) {
        addCard(
          label: 'MOST EXPENSIVE OVERALL',
          station: priciest,
          dimmed: true,
        );
      }
      return cards;
    }

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          sliver: SliverToBoxAdapter(child: _buildHeader(state)),
        ),
        if (cheapest != null && priciest != null)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            sliver: SliverToBoxAdapter(
              child: PriceRangeChart(
                cheapestPerLiter: cheapest.pricePerLiter,
                mostExpensivePerLiter: priciest.pricePerLiter,
                closestPerLiter: state.closestStation?.pricePerLiter,
                cheapestNearbyPerLiter: state.cheapestNearby?.pricePerLiter,
                mostExpensiveNearbyPerLiter:
                    state.mostExpensiveNearby?.pricePerLiter,
                capacityLiters: state.capacityLiters,
                fuelCode: state.fuelCode ?? '95',
              ),
            ),
          ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
          sliver: SliverToBoxAdapter(
            child: Text(
              'STATIONS',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.textBodyMedium,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            16,
            10,
            16,
            state.supportsRegulatedHistory &&
                    state.regulatedPriceHistory.isNotEmpty
                ? 16
                : 40,
          ),
          sliver: SliverList(delegate: SliverChildListDelegate(stationCards())),
        ),
        if (state.supportsRegulatedHistory &&
            state.regulatedPriceHistory.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
            sliver: SliverToBoxAdapter(
              child: TankCostHistoryInline(
                prices: state.regulatedPriceHistory,
                fuelCode: state.fuelCode ?? '95',
                fuelName:
                    state.fuelNames[state.fuelCode ?? ''] ??
                    (state.fuelCode ?? '95'),
                capacityLiters: state.capacityLiters,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLocationBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.glassFill,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.glassStroke),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.location_off_outlined,
            size: 18,
            color: AppColors.textBodyMedium,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Enable location to see nearby stations.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textBodyMedium),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(TankCalculatorState state) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.glassFill,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.glassStroke),
      ),
      child: Column(
        crossAxisAlignment: .start,
        spacing: 8,
        children: [
          _FuelChip(
            fuelCode: state.fuelCode ?? '',
            fuelNames: state.fuelNames,
            availableFuelCodes: state.availableFuelCodes,
          ),
          Divider(color: AppColors.glassStroke),
          _CapacityDisplay(liters: state.capacityLiters),
        ],
      ),
    );
  }
}
