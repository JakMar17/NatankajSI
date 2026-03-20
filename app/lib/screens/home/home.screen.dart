import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:app/data/data.dart';
import 'package:app/screens/stations_map/bloc/stations_map.cubit.dart';
import 'package:app/screens/stations_map/stations_map.screen.dart';
import 'package:app/screens/statistics/statistics.screen.dart';
import 'package:app/styles/styles.dart';

/// Root app shell with bottom tabs.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  bool _isStationSelected = false;
  late final StationsMapCubit _stationsMapCubit;

  @override
  void initState() {
    super.initState();
    _stationsMapCubit = StationsMapCubit(
      stationsApiService: context.read<StationsApiService>(),
      franchisesApiService: context.read<FranchisesApiService>(),
      fuelsApiService: context.read<FuelsApiService>(),
    )..loadData();
  }

  @override
  void dispose() {
    _stationsMapCubit.close();
    super.dispose();
  }

  void _onStationSelectionChanged(bool isSelected) {
    if (_isStationSelected == isSelected) {
      return;
    }

    setState(() => _isStationSelected = isSelected);
  }

  void _onStatisticsStationPressed(int stationPk) {
    _stationsMapCubit.selectStationByPk(stationPk);

    setState(() {
      _currentIndex = 0;
      _isStationSelected = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final shouldHideTabs = _currentIndex == 0 && _isStationSelected;
    final tabs = <Widget>[
      StationsMapScreen(
        cubit: _stationsMapCubit,
        onStationSelectionChanged: _onStationSelectionChanged,
      ),
      StatisticsScreen(onStationPressed: _onStatisticsStationPressed),
      const _MorePlaceholderView(),
    ];

    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppGradients.appBackground),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: IndexedStack(index: _currentIndex, children: tabs),
        bottomNavigationBar: shouldHideTabs
            ? null
            : NavigationBar(
                height: 72,
                selectedIndex: _currentIndex,
                onDestinationSelected: (index) {
                  setState(() => _currentIndex = index);
                },
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.map_outlined),
                    selectedIcon: Icon(Icons.map),
                    label: 'Map',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.bar_chart_outlined),
                    selectedIcon: Icon(Icons.bar_chart),
                    label: 'Statistics',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.grid_view_outlined),
                    selectedIcon: Icon(Icons.grid_view),
                    label: 'More',
                  ),
                ],
              ),
      ),
    );
  }
}

class _MorePlaceholderView extends StatelessWidget {
  const _MorePlaceholderView();

  @override
  Widget build(BuildContext context) {
    return const _TabPlaceholder(
      icon: Icons.grid_view_rounded,
      title: 'More',
      subtitle: 'Choose this tab name later',
    );
  }
}

class _TabPlaceholder extends StatelessWidget {
  const _TabPlaceholder({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: AppColors.bgSecondary,
                  border: Border.all(color: AppColors.glassStroke),
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: AppColors.accentBlue, size: 34),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: textTheme.bodyLarge?.copyWith(
                  color: AppColors.textBodyHigh,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
