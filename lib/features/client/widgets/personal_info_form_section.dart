import 'package:flutter/material.dart';
import 'profile_section_title.dart';

/// Form section for personal information (first name, last name)
/// 
/// Extracted from client_profile_screen.dart for better modularity.
class PersonalInfoFormSection extends StatelessWidget {
  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final VoidCallback onFieldChanged;

  const PersonalInfoFormSection({
    super.key,
    required this.firstNameController,
    required this.lastNameController,
    required this.onFieldChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ProfileSectionTitle(title: 'Informations personnelles'),
        const SizedBox(height: 16),
        
        // First name
        TextFormField(
          controller: firstNameController,
          decoration: const InputDecoration(
            labelText: 'Prénom',
            prefixIcon: Icon(Icons.person_outline),
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.words,
          validator: (value) =>
              value == null || value.isEmpty ? 'Le prénom est requis' : null,
          onChanged: (_) => onFieldChanged(),
        ),
        const SizedBox(height: 16),

        // Last name
        TextFormField(
          controller: lastNameController,
          decoration: const InputDecoration(
            labelText: 'Nom',
            prefixIcon: Icon(Icons.person_outline),
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.words,
          validator: (value) =>
              value == null || value.isEmpty ? 'Le nom est requis' : null,
          onChanged: (_) => onFieldChanged(),
        ),
      ],
    );
  }
}
