import 'package:app/screens/more/widgets/_menu_item.widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:app/data/services/regulated_prices.api_service.dart';
import 'package:app/screens/more/bloc/more.cubit.dart';
import 'package:app/screens/more/bloc/more.state.dart';
import 'package:app/screens/more/price_history/price_history.screen.dart';
import 'package:app/screens/more/tank_calculator/tank_calculator.screen.dart';
import 'package:app/screens/more/widgets/_regulated_prices_card.widget.dart';
import 'package:app/styles/styles.dart';

/// "More" tab — regulated prices card and navigation menu.
class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key, required this.onStationPressed});

  final void Function(int stationPk) onStationPressed;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<MoreCubit>(
      create: (context) => MoreCubit(
        regulatedPricesApiService: context.read<RegulatedPricesApiService>(),
      )..load(),
      child: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppGradients.appBackground),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(16, 24, 16, 0),
                  sliver: SliverToBoxAdapter(
                    child: Text(
                      'More',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
                const SliverPadding(
                  padding: EdgeInsets.fromLTRB(16, 20, 16, 0),
                  sliver: SliverToBoxAdapter(child: LatestPriceSlot()),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 28, 16, 0),
                  sliver: SliverToBoxAdapter(
                    child: Text(
                      'TOOLS',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textBodyMedium,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 40),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      spacing: 8,
                      children: [
                        MoreScreenMenuItem(
                          icon: Icons.local_gas_station_rounded,
                          label: 'Tank Calculator',
                          subtitle: 'Full tank cost across nearby stations',
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => TankCalculatorScreen(
                                onStationPressed: onStationPressed,
                              ),
                            ),
                          ),
                        ),
                        MoreScreenMenuItem(
                          icon: Icons.show_chart_rounded,
                          label: 'Price History',
                          subtitle: 'Regulated bencin & dizel over time',
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const PriceHistoryScreen(),
                            ),
                          ),
                        ),
                      ],
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

