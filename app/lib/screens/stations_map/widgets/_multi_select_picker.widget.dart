part of '../stations_map.screen.dart';

Future<Set<T>?> _showMultiSelectPicker<T>({
  required BuildContext context,
  required String title,
  required List<_SelectableItem<T>> options,
  required Set<T> initialSelectedValues,
}) {
  return showModalBottomSheet<Set<T>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF111A2B),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return _MultiSelectPicker<T>(
        title: title,
        options: options,
        initialSelectedValues: initialSelectedValues,
      );
    },
  );
}

class _MultiSelectPicker<T> extends StatefulWidget {
  const _MultiSelectPicker({
    required this.title,
    required this.options,
    required this.initialSelectedValues,
  });

  final String title;
  final List<_SelectableItem<T>> options;
  final Set<T> initialSelectedValues;

  @override
  State<_MultiSelectPicker<T>> createState() => _MultiSelectPickerState<T>();
}

class _MultiSelectPickerState<T> extends State<_MultiSelectPicker<T>> {
  late final Set<T> _selected;

  @override
  void initState() {
    super.initState();
    _selected = Set<T>.from(widget.initialSelectedValues);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.65,
          child: Column(
            children: [
              Row(
                children: [
                  Text(
                    widget.title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: widget.options.length,
                  itemBuilder: (context, index) {
                    final option = widget.options[index];
                    final isSelected = _selected.contains(option.value);
                    return CheckboxListTile.adaptive(
                      value: isSelected,
                      title: Text(option.label),
                      contentPadding: EdgeInsets.zero,
                      onChanged: (value) {
                        setState(() {
                          if (value ?? false) {
                            _selected.add(option.value);
                          } else {
                            _selected.remove(option.value);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _SheetActionButton(
                      label: 'Done',
                      onPressed: () => Navigator.of(context).pop(_selected),
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
}
