import 'package:flutter/material.dart';

class TagsSelector extends StatelessWidget {
  final List<String> availableTags;
  final List<String> selectedTags;
  final void Function(String tag, bool selected) onTagToggled;

  const TagsSelector({
    super.key,
    required this.availableTags,
    required this.selectedTags,
    required this.onTagToggled,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Services proposés (Tags)',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8.0,
          runSpacing: 4.0,
          children: availableTags.map((tag) {
            final isSelected = selectedTags.contains(tag);
            return FilterChip(
              label: Text(tag),
              selected: isSelected,
              onSelected: (bool selected) => onTagToggled(tag, selected),
            );
          }).toList(),
        ),
      ],
    );
  }
}
