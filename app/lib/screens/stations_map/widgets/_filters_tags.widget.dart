part of '../stations_map.screen.dart';

class _ActiveTagSection extends StatelessWidget {
  const _ActiveTagSection({
    required this.tags,
    required this.onAddPressed,
  });

  final List<_TagData> tags;
  final VoidCallback onAddPressed;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ...tags.mapToList(
          (tag) => InputChip(label: Text(tag.label), onDeleted: tag.onDeleted),
        ),
        ActionChip(
          avatar: const Icon(Icons.add_rounded, size: 18),
          label: const Text('Add'),
          onPressed: onAddPressed,
        ),
      ],
    );
  }
}

class _SelectableItem<T> {
  const _SelectableItem({required this.value, required this.label});

  final T value;
  final String label;
}

class _TagData {
  const _TagData({required this.label, required this.onDeleted});

  final String label;
  final VoidCallback onDeleted;
}
