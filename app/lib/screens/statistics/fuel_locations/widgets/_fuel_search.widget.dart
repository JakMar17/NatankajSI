part of '../fuel_locations.screen.dart';

class _SearchCard extends StatelessWidget {
  const _SearchCard({super.key});

  String _sortLabel({required FuelLocationsOrderBy orderBy}) {
    return switch (orderBy) {
      .distance => 'distance',
      .price => 'price',
    };
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<FuelLocationsCubit>().state;
    final sortLabel = _sortLabel(orderBy: state.orderBy);
    final directionLabel = state.isAscending ? 'Lowest first' : 'Higher first';

    return Column(
      spacing: 8,
      crossAxisAlignment: .start,
      mainAxisSize: .min,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                onChanged: context.read<FuelLocationsCubit>().setSearchQuery,
                decoration: InputDecoration(
                  hintText: 'Search by station, address, franchise',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: state.searchQuery.trim().isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            context.read<FuelLocationsCubit>().setSearchQuery('');
                          },
                          icon: const Icon(Icons.close_rounded),
                        ),
                ),
              ),
            ),
            IconButton(
          onPressed: () => _openFiltersSheet(context, state),
          icon: const Icon(Icons.tune_rounded),
        ),
          ],
        ),
        Text(
          'Sorted by $sortLabel, $directionLabel',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.textBodyMedium),
          textAlign: .start,
        ),
      ],
    );
  }

  void _openFiltersSheet(BuildContext context, FuelLocationsState state) {
    final cubit = context.read<FuelLocationsCubit>();

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: AppColors.bgSecondary,
      isScrollControlled: true,
      builder: (sheetContext) {
        var selectedOrder = state.orderBy;
        var isAscending = state.isAscending;

        return StatefulBuilder(
          builder: (context, setModalState) {
            final viewInsets = MediaQuery.of(context).viewInsets;

            return SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      10,
                      16,
                      24 + viewInsets.bottom,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minWidth: constraints.maxWidth,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Filters',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Order by',
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              ChoiceChip(
                                selected:
                                    selectedOrder ==
                                    FuelLocationsOrderBy.distance,
                                showCheckmark: false,
                                onSelected: (_) {
                                  setModalState(() {
                                    selectedOrder =
                                        FuelLocationsOrderBy.distance;
                                  });
                                },
                                label: const Text('Distance'),
                                avatar: const Icon(Icons.near_me_rounded),
                              ),
                              ChoiceChip(
                                selected:
                                    selectedOrder == FuelLocationsOrderBy.price,
                                showCheckmark: false,
                                onSelected: (_) {
                                  setModalState(() {
                                    selectedOrder = FuelLocationsOrderBy.price;
                                  });
                                },
                                label: const Text('Price'),
                                avatar: const Icon(Icons.local_gas_station),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Direction',
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: [
                              ChoiceChip(
                                selected: isAscending,
                                showCheckmark: false,
                                onSelected: (_) {
                                  setModalState(() => isAscending = true);
                                },
                                label: const Text('Lowest first'),
                                avatar: const Icon(Icons.south_rounded),
                              ),
                              ChoiceChip(
                                selected: !isAscending,
                                showCheckmark: false,
                                onSelected: (_) {
                                  setModalState(() => isAscending = false);
                                },
                                label: const Text('Higher first'),
                                avatar: const Icon(Icons.north_rounded),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                cubit.setOrderBy(selectedOrder);
                                cubit.setDirection(isAscending);
                                Navigator.of(sheetContext).pop();
                              },
                              child: const Text('Apply filters'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}
