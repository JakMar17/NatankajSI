part of '../stations_map.screen.dart';

class _MapActions extends StatelessWidget {
  const _MapActions();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const .only(top: 80, right: 12, left: 12),
        child: Align(
          alignment: .topRight,
          child: Row(
            mainAxisAlignment: .spaceBetween,
            children: const [
              _FilterButton(),
              _LocateMeButton(),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StationsMapCubit, StationsMapState>(
      buildWhen: (previous, current) {
        return previous.hasActiveFilters != current.hasActiveFilters;
      },
      builder: (context, state) {
        return _MapActionButton(
          tooltip: 'Filter stations',
          onPressed: () => _showFiltersSheet(context),
          icon: Icons.tune_rounded,
          showBadge: state.hasActiveFilters,
        );
      },
    );
  }

  Future<void> _showFiltersSheet(BuildContext context) {
    final cubit = context.read<StationsMapCubit>();
    final state = cubit.state;
    final franchises = state.franchisesById.values.toList()
      ..sort((left, right) => left.name.compareTo(right.name));
    final fuels = state.fuelsByCode.values.toList()
      ..sort((left, right) {
        final leftLabel = _fuelLabel(left).toLowerCase();
        final rightLabel = _fuelLabel(right).toLowerCase();
        return leftLabel.compareTo(rightLabel);
      });

    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF111A2B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return _FiltersBottomSheet(
          franchises: franchises,
          fuels: fuels,
          initialFranchiseIds: state.selectedFranchiseIds,
          initialFuelCodes: state.selectedFuelCodes,
          initialPreferredFuelCode: state.preferredFuelCode,
          onClearFilters: cubit.clearFilters,
          onApplyFilters: ({
            required franchiseIds,
            required fuelCodes,
            required preferredFuelCode,
          }) {
            cubit.applyFilters(
              franchiseIds: franchiseIds,
              fuelCodes: fuelCodes,
              preferredFuelCode: preferredFuelCode,
            );
          },
        );
      },
    );
  }

  String _fuelLabel(FuelType fuel) {
    final longName = fuel.longName?.trim();

    if (longName != null && longName.isNotEmpty) {
      return longName;
    }

    if (fuel.name.trim().isNotEmpty) {
      return fuel.name.trim();
    }

    return fuel.code;
  }
}

class _LocateMeButton extends StatelessWidget {
  const _LocateMeButton();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StationsMapCubit, StationsMapState>(
      buildWhen: (previous, current) {
        return previous.isLocating != current.isLocating;
      },
      builder: (context, state) {
        return _MapActionButton(
          tooltip: 'Center on my location',
          onPressed: () async {
            if (state.isLocating) {
              return;
            }

            final result = await context
                .read<StationsMapCubit>()
                .centerOnUserLocation();

            if (!context.mounted) {
              return;
            }

            _handleLocationResult(context, result);
          },
          child: state.isLocating
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(
                  Icons.my_location_rounded,
                  color: AppColors.textPrimary,
                ),
        );
      },
    );
  }

  void _handleLocationResult(
    BuildContext context,
    LocationCenteringResult result,
  ) {
    switch (result) {
      case LocationCenteringResult.success:
        return;
      case LocationCenteringResult.permissionDenied:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission denied.')),
        );
        return;
      case LocationCenteringResult.permissionDeniedForever:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Location permission is permanently denied.'),
            action: SnackBarAction(
              label: 'Settings',
              onPressed: Geolocator.openAppSettings,
            ),
          ),
        );
        return;
      case LocationCenteringResult.serviceDisabled:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Location services are disabled.'),
            action: SnackBarAction(
              label: 'Enable',
              onPressed: Geolocator.openLocationSettings,
            ),
          ),
        );
        return;
      case LocationCenteringResult.error:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not get current location.')),
        );
        return;
    }
  }
}

class _ActiveFilterDot extends StatelessWidget {
  const _ActiveFilterDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 9,
      height: 9,
      decoration: BoxDecoration(
        color: AppColors.accentMint,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF111A2B), width: 1.2),
      ),
    );
  }
}

class _MapActionButton extends StatelessWidget {
  const _MapActionButton({
    this.icon,
    this.child,
    required this.onPressed,
    required this.tooltip,
    this.showBadge = false,
  });

  final IconData? icon;
  final Widget? child;
  final VoidCallback? onPressed;
  final String tooltip;
  final bool showBadge;

  static const _buttonSize = 46.0;
  static const _iconSize = 22.0;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xE0111A2B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x55FFFFFF)),
      ),
      child: IconButton(
        onPressed: onPressed,
        tooltip: tooltip,
        padding: const EdgeInsets.all(0),
        constraints: const BoxConstraints.tightFor(
          width: _buttonSize,
          height: _buttonSize,
        ),
        splashRadius: 22,
        icon: Stack(
          clipBehavior: .none,
          alignment: .center,
          children: [
            SizedBox(
              width: _iconSize,
              height: _iconSize,
              child: Center(
                child:
                    child ??
                    Icon(icon, color: AppColors.textPrimary, size: _iconSize),
              ),
            ),
            if (showBadge)
              Align(
                alignment: Alignment.topRight,
                child: Transform.translate(
                  offset: const Offset(1, -1),
                  child: const _ActiveFilterDot(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
