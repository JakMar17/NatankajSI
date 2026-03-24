import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:app/data/data.dart';
import 'package:app/screens/startup/startup_gate.screen.dart';
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
      child: MaterialApp(
        title: 'NatankajSI',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkGlass,
        home: const StartupGateScreen(),
      ),
    );
  }
}
