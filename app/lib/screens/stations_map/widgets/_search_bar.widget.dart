part of '../stations_map.screen.dart';

class _SearchBar extends StatelessWidget {
  const _SearchBar();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StationsMapCubit, StationsMapState>(
      builder: (context, state) {
        final searchValue = TextEditingValue(
          text: state.searchQuery,
          selection: TextSelection.collapsed(offset: state.searchQuery.length),
        );

        return Column(
          mainAxisSize: .min,
          spacing: 8,
          children: [
            TextField(
              controller: TextEditingController.fromValue(searchValue),
              onChanged: (query) =>
                  context.read<StationsMapCubit>().onSearchQueryChanged(query),
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Search by station, address, ZIP, brand... ',
                hintStyle: TextStyle(color: Color(0xB3FFFFFF)),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: AppColors.textBodyHigh,
                ),
                suffixIcon: state.searchQuery.isNullOrEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          context.read<StationsMapCubit>().onSearchQueryChanged(
                            '',
                          );
                          FocusScope.of(context).unfocus();
                        },
                        icon: const Icon(
                          Icons.close_rounded,
                          color: AppColors.textBodyHigh,
                        ),
                      ),
                filled: true,
                fillColor: Color(0xC2202A3C),
              ),
            ),
            ?_buildSuggestionsDropdown(context: context, state: state),
          ],
        );
      },
    );
  }

  Widget? _buildSuggestionsDropdown({
    required BuildContext context,
    required StationsMapState state,
  }) {
    final stations = state.stations.take(_autocompleteMaxResults).toList();
    final franchisesById = state.franchisesById;

    if (state.searchQuery.isNullOrEmpty ||
        state.selectedStation != null ||
        stations.isEmpty) {
      return null;
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xE0111A2B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x55FFFFFF)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: stations.asMap().entries.mapToList(
          (entry) => _buildSuggestionEntry(
            context: context,
            index: entry.key,
            station: entry.value,
            totalCount: stations.length,
            franchisesById: franchisesById,
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestionEntry({
    required BuildContext context,
    required int index,
    required int totalCount,
    required StationWithPrices station,
    required Map<int, Franchise> franchisesById,
  }) {
    final franchise = station.franchiseId == null
        ? null
        : franchisesById[station.franchiseId];
    final subtitleParts = <String>[
      if (station.address.isNotNullOrEmpty) station.address!,
      if (station.zipCode.isNotNullOrEmpty) station.zipCode!,
      if (franchise?.name.isNotNullOrEmpty ?? false) franchise!.name,
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 2,
          ),
          leading: _buildSuggestionLogo(station: station, franchise: franchise),
          title: Text(
            station.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          subtitle: subtitleParts.isEmpty
              ? null
              : Text(
                  subtitleParts.join(' • '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
          onTap: () {
            FocusScope.of(context).unfocus();
            context.read<StationsMapCubit>().selectStationFromDropdown(station);
          },
        ),
        if (index < totalCount - 1)
          const Divider(height: 1, color: Color(0x33FFFFFF)),
      ],
    );
  }

  Widget _buildSuggestionLogo({
    required StationWithPrices station,
    required Franchise? franchise,
  }) {
    final logoUrl = franchise?.markerUrl;

    if (logoUrl.isNullOrEmpty) {
      return Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0x55FFFFFF),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
          Icons.local_gas_station_rounded,
          color: Color(0xAAFFFFFF),
          size: 20,
        ),
      );
    }

    return Image.network(logoUrl!, width: 36, height: 36);
  }
}
