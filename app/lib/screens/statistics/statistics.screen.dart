import 'package:app/screens/statistics/fuel_locations/fuel_locations.screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:app/data/data.dart';
import 'package:app/screens/statistics/bloc/statistics.cubit.dart';
import 'package:app/screens/statistics/bloc/statistics.state.dart';
import 'package:app/styles/styles.dart';
import 'package:app/widgets/base/base.dart';

/// Shows aggregated price metrics for each fuel type.
class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key, required this.onStationPressed});

  final ValueChanged<int> onStationPressed;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<StatisticsCubit>(
      create: (context) => StatisticsCubit(
        stationsApiService: context.read<StationsApiService>(),
        fuelsApiService: context.read<FuelsApiService>(),
      )..load(),
      child: _StatisticsView(onStationPressed: onStationPressed),
    );
  }
}

class _StatisticsView extends StatelessWidget {
  const _StatisticsView({required this.onStationPressed});

  final ValueChanged<int> onStationPressed;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StatisticsCubit, StatisticsState>(
      builder: (context, state) {
        return DecoratedBox(
          decoration: const BoxDecoration(gradient: AppGradients.appBackground),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: SafeArea(
              child: switch (state.status) {
                StatisticsStatus.loading => const Center(
                  child: CircularProgressIndicator(),
                ),
                StatisticsStatus.error => _StatisticsErrorView(
                  message: state.errorMessage ?? 'Could not load statistics.',
                  onRetry: context.read<StatisticsCubit>().load,
                ),
                StatisticsStatus.ready => _StatisticsReadyView(
                  state: state,
                  onStationPressed: onStationPressed,
                ),
              },
            ),
          ),
        );
      },
    );
  }
}

class _StatisticsReadyView extends StatelessWidget {
  const _StatisticsReadyView({
    required this.state,
    required this.onStationPressed,
  });

  final StatisticsState state;
  final ValueChanged<int> onStationPressed;

  @override
  Widget build(BuildContext context) {
    if (state.fuelStats.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'No fuel price data available.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textPrimary),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
      itemCount: state.fuelStats.length + 1,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        if (index == 0) {
          return _StatisticsHeader(state: state);
        }

        final statistics = state.fuelStats[index - 1];

        return _FuelStatisticsCard(
          statistics: statistics,
          onStationPressed: onStationPressed,
        );
      },
    );
  }
}

class _StatisticsHeader extends StatelessWidget {
  const _StatisticsHeader({required this.state});

  final StatisticsState state;

  @override
  Widget build(BuildContext context) {
    final generatedText = state.generatedAt == null
        ? 'Updated now'
        : 'Updated ${_formatTime(state.generatedAt!)}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 2, 6, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Fuel Statistics',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            'Overview of market price levels and spread by fuel type.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textBodyHigh),
          ),
          const SizedBox(height: 10),
          Text(
            generatedText,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textBodyMedium),
          ),
          if (state.userLocation == null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'Enable location to show nearest station distance.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textBodyMedium,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }
}

class _FuelStatisticsCard extends StatelessWidget {
  const _FuelStatisticsCard({
    required this.statistics,
    required this.onStationPressed,
  });

  final FuelStatistics statistics;
  final ValueChanged<int> onStationPressed;

  void _openDetail(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => FuelLocationsScreen(
          fuelCode: statistics.fuelCode,
          fuelLabel: statistics.fuelLabel,
          statistics: statistics,
          onStationPressed: onStationPressed,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = FuelCardPalette.fromCode(statistics.fuelCode);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[palette.startColor, palette.endColor],
        ),
        border: Border.all(color: AppColors.glassStroke),
      ),
      child: GlassCard(
        borderRadius: 22,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: () => _openDetail(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statistics.fuelLabel,
                  style: Theme.of(context).textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                Align(
                  alignment: .centerRight,
                  child: Text(
                    '${statistics.primaryPrice.toStringAsFixed(3)} EUR',
                    textAlign: TextAlign.right,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: palette.iconColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatisticsErrorView extends StatelessWidget {
  const _StatisticsErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
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
