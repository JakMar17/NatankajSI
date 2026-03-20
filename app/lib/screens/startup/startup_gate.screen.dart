import 'package:dart_util_box/dart_util_box.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:app/data/data.dart';
import 'package:app/screens/home/home.screen.dart';
import 'package:app/screens/startup/bloc/startup_gate.cubit.dart';
import 'package:app/screens/startup/bloc/startup_gate.state.dart';
import 'package:app/styles/styles.dart';
import 'package:app/widgets/base/base.dart';

/// Decides whether to show first-run fuel preference onboarding.
class StartupGateScreen extends StatelessWidget {
  const StartupGateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<StartupGateCubit>(
      create: (context) =>
          StartupGateCubit(fuelsApiService: context.read<FuelsApiService>())
            ..load(),
      child: BlocBuilder<StartupGateCubit, StartupGateState>(
        builder: (context, state) {
          switch (state.status) {
            case StartupGateStatus.loading:
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            case StartupGateStatus.error:
              return _StartupErrorView(
                onRetry: context.read<StartupGateCubit>().load,
              );
            case StartupGateStatus.ready:
              return const HomeScreen();
            case StartupGateStatus.selectPreference:
              return _FuelPreferenceWelcomeScreen(
                fuels: state.fuels,
                selectedFuelCode: state.selectedFuelCode,
                isSaving: state.isSaving,
                onFuelSelected: context.read<StartupGateCubit>().selectFuelCode,
                onContinue: context.read<StartupGateCubit>().confirmSelection,
                fuelLabelResolver: context
                    .read<StartupGateCubit>()
                    .labelForFuel,
              );
          }
        },
      ),
    );
  }
}

class _StartupErrorView extends StatelessWidget {
  const _StartupErrorView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Could not prepare app startup.',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Please try again.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ),
        ),
      ),
    );
  }
}

class _FuelPreferenceWelcomeScreen extends StatelessWidget {
  const _FuelPreferenceWelcomeScreen({
    required this.fuels,
    required this.selectedFuelCode,
    required this.isSaving,
    required this.onFuelSelected,
    required this.onContinue,
    required this.fuelLabelResolver,
  });

  final List<FuelType> fuels;
  final String? selectedFuelCode;
  final bool isSaving;
  final ValueChanged<String?> onFuelSelected;
  final Future<void> Function() onContinue;
  final String Function(FuelType fuel) fuelLabelResolver;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.appBackground),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                GradientIconBadge(
                  icon: Icons.local_gas_station,
                  iconColor: AppColors.bgPrimary,
                ),
                const SizedBox(height: 20),
                Text(
                  'Welcome to NatankajSI',
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Choose your preferred fuel type. We will use it by default '
                  'for map markers and station highlights.',
                  style: textTheme.bodyLarge?.copyWith(
                    color: AppColors.textBodyHigh,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 22),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: fuels.mapToList(
                        (fuel) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _FuelOptionCard(
                            fuel: fuel,
                            label: fuelLabelResolver(fuel),
                            isSelected:
                                selectedFuelCode == fuel.code.toLowerCase(),
                            onTap: () {
                              onFuelSelected(fuel.code.toLowerCase());
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: isSaving || selectedFuelCode == null
                      ? null
                      : onContinue,
                  child: isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Continue'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FuelOptionCard extends StatelessWidget {
  const _FuelOptionCard({
    required this.fuel,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final FuelType fuel;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  String get _subtitle {
    final shortName = fuel.name.trim();
    final code = fuel.code.trim();

    if (shortName.isNotEmpty) {
      return '$shortName · $code';
    }

    return code;
  }

  @override
  Widget build(BuildContext context) {
    final palette = FuelCardPalette.fromCode(fuel.code);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[palette.startColor, palette.endColor],
            ),
            border: Border.all(
              color: isSelected ? palette.iconColor : AppColors.glassStroke,
              width: isSelected ? 1.6 : 1,
            ),
          ),
          child: Row(
            spacing: 12,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0x29000000),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.local_gas_station_outlined,
                  size: 18,
                  color: palette.iconColor,
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      _subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textBodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(Icons.check_circle, size: 20, color: palette.iconColor),
            ],
          ),
        ),
      ),
    );
  }
}
