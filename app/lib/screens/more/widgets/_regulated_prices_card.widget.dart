import 'package:app/screens/more/bloc/more.cubit.dart';
import 'package:app/screens/more/bloc/more.state.dart';
import 'package:flutter/material.dart';

import 'package:app/data/models/regulated_price.model.dart';
import 'package:app/styles/styles.dart';
import 'package:app/widgets/base/base.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LatestPriceSlot extends StatelessWidget {
  const LatestPriceSlot();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MoreCubit, MoreState>(
      builder: (context, state) => switch (state.status) {
        .loading => _buildLoadingSkeleton(),
        .error => const SizedBox.shrink(),
        .ready =>
          state.latestPrice != null
              ? LatestRegulatedPricesCard(price: state.latestPrice!)
              : const SizedBox.shrink(),
      },
    );
  }

  Widget _buildLoadingSkeleton() {
    return Container(
      height: 128,
      decoration: BoxDecoration(
        color: AppColors.glassFill,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.glassStroke),
      ),
      alignment: Alignment.center,
      child: const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }
}

/// Shows the current government-regulated prices for bencin and diesel.
class LatestRegulatedPricesCard extends StatelessWidget {
  const LatestRegulatedPricesCard({super.key, required this.price});

  final RegulatedPrice price;

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 16,
      crossAxisAlignment: .start,
      children: [
        Text(
          'Regulated Prices'.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppColors.textBodyMedium,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        Row(
          spacing: 16,
          children: [
            Expanded(
              child: _PriceTile(
                label: 'Bencin 95',
                price: price.petrolPrice,
                color: FuelCardPalette.fromCode('95').iconColor,
              ),
            ),
            Expanded(
              child: _PriceTile(
                label: 'Dizel',
                price: price.dieselPrice,
                color: FuelCardPalette.fromCode('dizel').iconColor,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PriceTile extends StatelessWidget {
  const _PriceTile({
    required this.label,
    required this.price,
    required this.color,
  });

  final String label;
  final double? price;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.glassFill,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.glassStroke),
      ),
      child: Column(
        crossAxisAlignment: .start,
        spacing: 4,
        children: [
          Text(
            label,
            style: textTheme.labelSmall?.copyWith(
              color: AppColors.textBodyMedium,
              fontWeight: FontWeight.w600,
            ),
          ),
          Align(
            alignment: .centerRight,
            child: Text(
              price != null ? '${price!.toStringAsFixed(3)} €' : '–',
              style: textTheme.titleLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
              ),
              textAlign: .end,
            ),
          ),
        ],
      ),
    );
  }
}
