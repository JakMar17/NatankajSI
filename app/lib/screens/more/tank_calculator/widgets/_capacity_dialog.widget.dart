part of '../tank_calculator.screen.dart';

class _CapacityDisplay extends StatelessWidget {
  const _CapacityDisplay({required this.liters});

  final double liters;

  Future<void> _openModal(BuildContext context) async {
    final cubit = context.read<TankCalculatorCubit>();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => _CapacityDialog(
        initialLiters: liters,
        onConfirm: (value) => cubit.setCapacity(value),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: () => _openModal(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        spacing: 8,
        children: [
          Text(
            'TANK CAPACITY',
            style: textTheme.labelSmall?.copyWith(
              color: AppColors.textBodyMedium,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          Row(
            crossAxisAlignment: .center,
            mainAxisAlignment: .end,
            spacing: 16,
            children: [
              Flexible(
                child: Row(
                  mainAxisSize: .min,
                  crossAxisAlignment: .end,
                  spacing: 4,
                  children: [
                    Text(
                      liters.toStringAsFixed(0),
                      style: textTheme.titleLarge?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'L',
                      style: textTheme.titleMedium?.copyWith(
                        color: AppColors.textBodyMedium,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.edit_outlined,
                size: 15,
                color: AppColors.textBodyMedium,
              ),
            ],
          ),
        ],
      ),
    );
  }
}



class _CapacityDialog extends StatefulWidget {
  const _CapacityDialog({required this.initialLiters, required this.onConfirm});

  final double initialLiters;
  final void Function(double liters) onConfirm;

  @override
  State<_CapacityDialog> createState() => _CapacityDialogState();
}

class _CapacityDialogState extends State<_CapacityDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.initialLiters.toStringAsFixed(0),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _confirm() {
    final parsed = double.tryParse(_controller.text);
    if (parsed != null && parsed > 0) {
      widget.onConfirm(parsed);
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Dialog(
      backgroundColor: AppColors.bgSecondary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: AppColors.glassStroke),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: .min,
          crossAxisAlignment: .start,
          spacing: 16,
          children: [
            Text(
              'Tank capacity',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            TextField(
              controller: _controller,
              autofocus: true,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onSubmitted: (value) => _confirm(),
              style: textTheme.headlineSmall?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                suffix: Text(
                  'L',
                  style: textTheme.titleMedium?.copyWith(
                    color: AppColors.textBodyMedium,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            Row(
              spacing: 16,
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'Cancel',
                      style: textTheme.labelLarge?.copyWith(
                        color: AppColors.textBodyMedium,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: TextButton(
                    onPressed: _confirm,
                    child: Text(
                      'Confirm',
                      style: textTheme.labelLarge?.copyWith(
                        color: AppColors.accentBlue,
                        fontWeight: .w900,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
