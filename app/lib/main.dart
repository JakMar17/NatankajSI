import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:app/data/data.dart';
import 'package:app/screens/more/bloc/more.cubit.dart';
import 'package:app/screens/startup/startup_gate.screen.dart';
import 'package:app/screens/statistics/bloc/statistics.cubit.dart';
import 'package:app/styles/styles.dart';

const String _apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://natankaj.sven.marela.team',
);

void main() {
  runApp(const FuelApp());
}

class FuelApp extends StatelessWidget {
  const FuelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AppBootRepository>(
          create: (_) => AppBootRepository(),
        ),
        RepositoryProvider<ApiClientService>(
          create: (_) => ApiClientService(baseUrl: _apiBaseUrl),
        ),
        RepositoryProvider<StationsApiService>(
          create: (context) =>
              StationsApiService(context.read<ApiClientService>().dio),
        ),
        RepositoryProvider<FranchisesApiService>(
          create: (context) =>
              FranchisesApiService(context.read<ApiClientService>().dio),
        ),
        RepositoryProvider<FuelsApiService>(
          create: (context) =>
              FuelsApiService(context.read<ApiClientService>().dio),
        ),
        RepositoryProvider<RegulatedPricesApiService>(
          create: (context) => RegulatedPricesApiService(
            context.read<ApiClientService>().dio,
          ),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<StatisticsCubit>(
            create: (context) => StatisticsCubit(
              stationsApiService: context.read<StationsApiService>(),
              fuelsApiService: context.read<FuelsApiService>(),
              appBootRepository: context.read<AppBootRepository>(),
            ),
          ),
          BlocProvider<MoreCubit>(
            create: (context) => MoreCubit(
              regulatedPricesApiService:
                  context.read<RegulatedPricesApiService>(),
              appBootRepository: context.read<AppBootRepository>(),
            ),
          ),
        ],
        child: MaterialApp(
          title: 'NatankajSI',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.darkGlass,
          home: const StartupGateScreen(),
        ),
      ),
    );
  }
}
