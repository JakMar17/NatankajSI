part of '../fuel_locations.screen.dart';

class _HeaderSection extends StatelessWidget {
  const _HeaderSection({
    required this.fuelCode,
    required this.fuelLabel,
    required this.state,
  });

  final String fuelCode;
  final String fuelLabel;

  final FuelLocationsState state;

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 8,
      children: [
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        Expanded(
          child: Text(
            fuelLabel,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: .w700),
            textAlign: .center,
          ),
        ),
        Opacity(
          opacity: 0,
          child: IconButton(
            onPressed: () => null,
            icon: const Icon(Icons.arrow_back_rounded),
          ),
        ),
      ],
    );
  }
}
