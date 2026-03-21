part of "../fuel_locations.screen.dart";

class _FuelLocationsLoadedView extends StatelessWidget {
  final String fuelCode;
  final String fuelLabel;
  final ValueChanged<int> onStationPressed;

  const _FuelLocationsLoadedView({
    required this.fuelCode,
    required this.fuelLabel,
    required this.onStationPressed,
  });

  @override
  Widget build(BuildContext context) {
    final state = context.watch<FuelLocationsCubit>().state;
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: _HeaderSection(
              fuelCode: fuelCode,
              fuelLabel: fuelLabel,
              state: state,
            ),
          ),
          const _GlassTabBar(),
          Expanded(
            child: TabBarView(
              children: [
                _FuelLocationsStatisticsTab(
                  statistics: state.statistics,
                  onStationPressed: onStationPressed,
                ),
                _buildLocationsTab(state),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationsTab(FuelLocationsState state) {
    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: _SearchCard(),
        ),
        state.visibleItems.isEmpty
            ? _buildEmptyResults()
            : _buildResultsList(
                state.visibleItems,
                averagePrice: state.statistics?.averagePrice,
              ),
      ],
    );
  }

  Widget _buildEmptyResults() {
    return const Padding(
      padding: EdgeInsets.all(24),
      child: Text(
        'No stations match current search/filter.',
        textAlign: TextAlign.center,
        style: TextStyle(color: AppColors.textPrimary),
      ),
    );
  }

  Widget _buildResultsList(
    List<FuelLocationItem> items, {
    required double? averagePrice,
  }) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 18),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = items[index];

        return _LocationCard(
          item: item,
          fuelCode: fuelCode,
          averagePrice: averagePrice,
          onPressed: () {
            onStationPressed(item.stationPk);
            Navigator.of(context).pop();
          },
        );
      },
    );
  }
}

class _GlassTabBar extends StatelessWidget {
  const _GlassTabBar();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.glassFill,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.glassStroke),
            ),
            child: TabBar(
              indicator: BoxDecoration(
                color: const Color(0x55FFFFFF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.glassStroke),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              overlayColor: WidgetStateProperty.all(Colors.transparent),
              labelColor: AppColors.textPrimary,
              unselectedLabelColor: AppColors.textBodyMedium,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
              tabs: const [
                Tab(text: 'Statistics', height: 36),
                Tab(text: 'Locations', height: 36),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
