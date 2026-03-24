import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import 'package:app/data/services/regulated_prices.api_service.dart';
import 'package:app/screens/more/price_history/bloc/price_history.cubit.dart';
import 'package:app/screens/more/price_history/bloc/price_history.state.dart';
import 'package:app/screens/more/price_history/widgets/_price_chart.widget.dart';
import 'package:app/styles/styles.dart';

/// Shows regulated fuel price history as a line chart.
class PriceHistoryScreen extends StatelessWidget {
  const PriceHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<PriceHistoryCubit>(
      create: (context) => PriceHistoryCubit(
        regulatedPricesApiService:
            context.read<RegulatedPricesApiService>(),
      )..load(),
      child: const _PriceHistoryView(),
    );
  }
}

class _PriceHistoryView extends StatelessWidget {
  const _PriceHistoryView();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: AppGradients.appBackground,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('Price History'),
        ),
        body: const Column(
          spacing: 24,
          children: [
            _Controls(),
            Expanded(child: _ChartArea()),
          ],
        ),
      ),
    );
  }
}

/// Period pills + date nav in a single column section.
class _Controls extends StatelessWidget {
  const _Controls();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PriceHistoryCubit, PriceHistoryState>(
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
          child: Column(
            spacing: 12,
            children: [
              Row(
                children: [
                  Expanded(child: _PeriodPills(current: state.period)),
                  const SizedBox(width: 10),
                  Expanded(child: _FuelSelector(current: state.fuelView)),
                ],
              ),
              if (state.period == PeriodType.year)
                _DateNavRow(state: state),
            ],
          ),
        );
      },
    );
  }
}

class _PeriodPills extends StatelessWidget {
  const _PeriodPills({required this.current});

  final PeriodType current;

  static const _labels = {
    PeriodType.year: 'Y',
    PeriodType.all: 'All',
  };

  @override
  Widget build(BuildContext context) {
    return _PillRow<PeriodType>(
      values: PeriodType.values,
      selected: current,
      labelOf: (p) => _labels[p]!,
      onTap: context.read<PriceHistoryCubit>().selectPeriod,
    );
  }
}

class _FuelSelector extends StatelessWidget {
  const _FuelSelector({required this.current});

  final FuelView current;

  static const _labels = {
    FuelView.petrol: 'Bencin',
    FuelView.diesel: 'Dizel',
    FuelView.both: 'Oba',
  };

  @override
  Widget build(BuildContext context) {
    return _PillRow<FuelView>(
      values: FuelView.values,
      selected: current,
      labelOf: (f) => _labels[f]!,
      onTap: context.read<PriceHistoryCubit>().selectFuel,
    );
  }
}

/// Generic animated pill row.
class _PillRow<T> extends StatelessWidget {
  const _PillRow({
    required this.values,
    required this.selected,
    required this.labelOf,
    required this.onTap,
  });

  final List<T> values;
  final T selected;
  final String Function(T) labelOf;
  final void Function(T) onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.glassFill,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.glassStroke),
      ),
      child: Row(
        children: values.map((value) {
          final isSelected = value == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onTap(value),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 7),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.accentBlue
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(7),
                ),
                alignment: Alignment.center,
                child: Text(
                  labelOf(value),
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isSelected
                        ? AppColors.bgPrimary
                        : AppColors.textBodyMedium,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _DateNavRow extends StatelessWidget {
  const _DateNavRow({required this.state});

  final PriceHistoryState state;

  static final _fmt = DateFormat('yyyy');

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PriceHistoryCubit>();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          _NavButton(icon: Icons.chevron_left, onTap: cubit.goPrevious),
          Expanded(
            child: Text(
              _fmt.format(state.fromDate),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textBodyHigh,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          _NavButton(
            icon: Icons.chevron_right,
            onTap: state.canGoNext ? cubit.goNext : null,
          ),
        ],
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: enabled ? AppColors.glassFill : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: enabled ? AppColors.glassStroke : Colors.transparent,
          ),
        ),
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: 20,
          color: enabled
              ? AppColors.textBodyHigh
              : AppColors.textBodyMedium.withAlpha(60),
        ),
      ),
    );
  }
}

class _ChartArea extends StatelessWidget {
  const _ChartArea();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PriceHistoryCubit, PriceHistoryState>(
      builder: (context, state) => switch (state.status) {
        PriceHistoryStatus.loading => const Center(
          child: CircularProgressIndicator(),
        ),
        PriceHistoryStatus.error => _ErrorView(
          message: state.errorMessage ?? 'Error loading data.',
          onRetry: context.read<PriceHistoryCubit>().load,
        ),
        PriceHistoryStatus.ready => Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: PriceLineChart(
            prices: state.prices,
            showPetrol: state.fuelView != FuelView.diesel,
            showDiesel: state.fuelView != FuelView.petrol,
            touchedX: state.touchedX,
            onTouched: context.read<PriceHistoryCubit>().setTouchedX,
          ),
        ),
      },
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

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
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
