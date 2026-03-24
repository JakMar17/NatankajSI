part of '../tank_calculator.screen.dart';

class _FuelSelectorSheet extends StatelessWidget {
  const _FuelSelectorSheet({
    required this.selected,
    required this.codes,
    required this.fuelNames,
    required this.scrollController,
    required this.onSelect,
  });

  final String selected;
  final List<String> codes;
  final Map<String, String> fuelNames;
  final ScrollController scrollController;
  final void Function(String code) onSelect;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      children: [
        Center(
          child: Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.glassStroke,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'SELECT FUEL TYPE',
          style: textTheme.labelSmall?.copyWith(
            color: AppColors.textBodyMedium,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        ...codes.map((code) {
          final isSelected = code == selected;
          final color = FuelCardPalette.fromCode(code).iconColor;
          final name = fuelNames[code] ?? code.toUpperCase();
          return _FuelOption(
            name: name,
            color: color,
            isSelected: isSelected,
            onTap: () => onSelect(code),
          );
        }),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _FuelOption extends StatelessWidget {
  const _FuelOption({
    required this.name,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  final String name;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          decoration: BoxDecoration(
            color: isSelected ? color.withAlpha(20) : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: isSelected ? Border.all(color: color.withAlpha(60)) : null,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              spacing: 14,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    name,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isSelected
                          ? AppColors.textBodyHigh
                          : AppColors.textBodyMedium,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w400,
                    ),
                  ),
                ),
                if (isSelected) Icon(Icons.check, size: 18, color: color),
              ],
            ),
          ),
        ),
      ),
    );
  }
}