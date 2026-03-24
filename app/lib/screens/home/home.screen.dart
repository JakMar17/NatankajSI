import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:app/data/data.dart';
import 'package:app/screens/more/more.screen.dart';
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
      MoreScreen(onStationPressed: _onStatisticsStationPressed),
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

