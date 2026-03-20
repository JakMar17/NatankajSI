part of '../stations_map.screen.dart';

class _FiltersBottomSheet extends StatefulWidget {
  const _FiltersBottomSheet({
    required this.franchises,
    required this.fuels,
    required this.initialFranchiseIds,
    required this.initialFuelCodes,
    required this.initialPreferredFuelCode,
    required this.onClearFilters,
    required this.onApplyFilters,
  });

  final List<Franchise> franchises;
  final List<FuelType> fuels;
  final Set<int> initialFranchiseIds;
  final Set<String> initialFuelCodes;
  final String? initialPreferredFuelCode;
  final VoidCallback onClearFilters;
  final void Function({
    required Set<int> franchiseIds,
    required Set<String> fuelCodes,
    required String? preferredFuelCode,
  })
  onApplyFilters;

  @override
  State<_FiltersBottomSheet> createState() => _FiltersBottomSheetState();
}

class _FiltersBottomSheetState extends State<_FiltersBottomSheet> {
  late final Set<int> _selectedFranchiseIds;
  late final Set<String> _selectedFuelCodes;
  late String? _preferredFuelCode;

  @override
  void initState() {
    super.initState();
    _selectedFranchiseIds = Set<int>.from(widget.initialFranchiseIds);
    _selectedFuelCodes = Set<String>.from(widget.initialFuelCodes);
    _preferredFuelCode = widget.initialPreferredFuelCode;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          10,
          16,
          MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.72,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(
                    'Filter stations',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                    tooltip: 'Close filters',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _FilterSection(
                        title: 'Company',
                        child: _ActiveTagSection(
                          tags: _selectedFranchiseIds.mapToList((id) {
                            final franchise = widget.franchises.firstWhere(
                              (item) => item.pk == id,
                              orElse: () => Franchise(
                                pk: id,
                                name: 'Unknown company',
                                markerUrl: null,
                                markerHoverUrl: null,
                              ),
                            );

                            return _TagData(
                              label: franchise.name,
                              onDeleted: () {
                                setState(() {
                                  _selectedFranchiseIds.remove(id);
                                });
                              },
                            );
                          }),
                          onAddPressed: _onAddCompanies,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _FilterSection(
                        title: 'Fuel type',
                        child: _ActiveTagSection(
                          tags: _selectedFuelCodes.mapToList((code) {
                            final fuel = widget.fuels.firstWhere(
                              (item) => item.code.toLowerCase() == code,
                              orElse: () => FuelType(
                                pk: -1,
                                code: code,
                                name: code.toUpperCase(),
                                longName: null,
                              ),
                            );

                            return _TagData(
                              label: _fuelLabel(fuel),
                              onDeleted: () {
                                setState(() {
                                  _selectedFuelCodes.remove(code);
                                });
                              },
                            );
                          }),
                          onAddPressed: _onAddFuelTypes,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _FilterSection(
                        title: 'Preferred fuel on marker',
                        child: DropdownButtonFormField<String?>(
                          value: _preferredFuelCode,
                          decoration: const InputDecoration(
                            isDense: true,
                            hintText: 'Use default marker fuel',
                          ),
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text('Default (95 or first available)'),
                            ),
                            ...widget.fuels.mapToList(
                              (fuel) => DropdownMenuItem<String?>(
                                value: fuel.code.toLowerCase(),
                                child: Text(_fuelLabel(fuel)),
                              ),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _preferredFuelCode = value;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _SheetActionButton(
                      label: 'Apply',
                      onPressed: () {
                        widget.onApplyFilters(
                          franchiseIds: _selectedFranchiseIds,
                          fuelCodes: _selectedFuelCodes,
                          preferredFuelCode: _preferredFuelCode,
                        );
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
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

  Future<void> _onAddCompanies() async {
    final selected = await _showMultiSelectPicker<int>(
      context: context,
      title: 'Select companies',
      options: widget.franchises.mapToList(
        (franchise) =>
            _SelectableItem<int>(value: franchise.pk, label: franchise.name),
      ),
      initialSelectedValues: _selectedFranchiseIds,
    );

    if (selected == null) {
      return;
    }

    setState(() {
      _selectedFranchiseIds
        ..clear()
        ..addAll(selected);
    });
  }

  Future<void> _onAddFuelTypes() async {
    final selected = await _showMultiSelectPicker<String>(
      context: context,
      title: 'Select fuel types',
      options: widget.fuels.mapToList(
        (fuel) => _SelectableItem<String>(
          value: fuel.code.toLowerCase(),
          label: _fuelLabel(fuel),
        ),
      ),
      initialSelectedValues: _selectedFuelCodes,
    );

    if (selected == null) {
      return;
    }

    setState(() {
      _selectedFuelCodes
        ..clear()
        ..addAll(selected);
    });
  }
}

class _SheetActionButton extends StatelessWidget {
  const _SheetActionButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(44)),
      child: Text(label),
    );
  }
}

class _FilterSection extends StatelessWidget {
  const _FilterSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}
