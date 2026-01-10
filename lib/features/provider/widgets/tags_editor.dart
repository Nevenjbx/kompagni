import 'package:flutter/material.dart';

/// Widget for editing provider tags with chips
/// 
/// Displays available tags as selectable chips and manages selection state.
class TagsEditor extends StatelessWidget {
  final List<String> availableTags;
  final List<String> selectedTags;
  final ValueChanged<List<String>> onTagsChanged;

  const TagsEditor({
    super.key,
    required this.availableTags,
    required this.selectedTags,
    required this.onTagsChanged,
  });

  static const List<String> defaultTags = [
    'Toiletteur',
    'Vétérinaire',
    'Pension',
    'Promenade',
    'Chien',
    'Chat',
    'Éducation',
    'Garde à domicile',
  ];

  void _toggleTag(String tag) {
    final newTags = List<String>.from(selectedTags);
    if (newTags.contains(tag)) {
      newTags.remove(tag);
    } else {
      newTags.add(tag);
    }
    onTagsChanged(newTags);
  }

  @override
  Widget build(BuildContext context) {
    final tags = availableTags.isEmpty ? defaultTags : availableTags;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tags / Spécialités',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Sélectionnez les tags qui correspondent à vos services',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: tags.map((tag) {
            final isSelected = selectedTags.contains(tag);
            return FilterChip(
              selected: isSelected,
              label: Text(tag),
              onSelected: (_) => _toggleTag(tag),
              selectedColor: Theme.of(context).colorScheme.primaryContainer,
              checkmarkColor: Theme.of(context).colorScheme.onPrimaryContainer,
            );
          }).toList(),
        ),
      ],
    );
  }
}
