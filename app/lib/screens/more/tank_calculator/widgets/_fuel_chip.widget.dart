part of '../tank_calculator.screen.dart';


class _FuelChip extends StatelessWidget {
  const _FuelChip({
    required this.fuelCode,
    required this.fuelNames,
    required this.availableFuelCodes,
  });

  final String fuelCode;
  final Map<String, String> fuelNames;
  final List<String> availableFuelCodes;

  void _openBottomSheet(BuildContext context) {
    final cubit = context.read<TankCalculatorCubit>();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgSecondary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.85,
        builder: (_, controller) => _FuelSelectorSheet(
          selected: fuelCode,
          codes: availableFuelCodes,
          fuelNames: fuelNames,
          scrollController: controller,
          onSelect: (code) {
            Navigator.of(sheetContext).pop();
            cubit.selectFuel(code);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = FuelCardPalette.fromCode(fuelCode).iconColor;
    final displayName = fuelNames[fuelCode] ?? fuelCode.toUpperCase();
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: () => _openBottomSheet(context),
      child: Column(
        crossAxisAlignment: .start,
        mainAxisSize: .min,
        spacing: 8,
        children: [
          Text(
            'FUEL TYPE',
            style: textTheme.labelSmall?.copyWith(
              color: AppColors.textBodyMedium,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          Row(
            spacing: 16,
            mainAxisAlignment: .end,
            children: [
              Flexible(
                child: Text(
                  displayName,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Icon(Icons.tune, size: 18),
            ],
          ),
        ],
      ),
    );
  }
}

