import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/countries.dart';
import 'profile_section_title.dart';

/// Form section for contact information (email, phone)
/// 
/// Extracted from client_profile_screen.dart for better modularity.
class ContactInfoFormSection extends StatelessWidget {
  final TextEditingController emailController;
  final String? phoneNumber;
  final ValueChanged<String> onPhoneChanged;
  final VoidCallback onFieldChanged;

  const ContactInfoFormSection({
    super.key,
    required this.emailController,
    this.phoneNumber,
    required this.onPhoneChanged,
    required this.onFieldChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ProfileSectionTitle(title: 'Coordonnées'),
        const SizedBox(height: 16),

        // Email
        TextFormField(
          controller: emailController,
          decoration: const InputDecoration(
            labelText: 'Email',
            prefixIcon: Icon(Icons.email_outlined),
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'L\'email est requis';
            }
            if (!value.contains('@')) {
              return 'Veuillez entrer un email valide';
            }
            return null;
          },
          onChanged: (_) => onFieldChanged(),
        ),
        const SizedBox(height: 16),

        // Phone
        IntlPhoneField(
          key: Key(phoneNumber ?? 'phone_field'),
          decoration: const InputDecoration(
            labelText: 'Numéro de téléphone',
            border: OutlineInputBorder(),
          ),
          initialCountryCode: 'FR',
          initialValue: phoneNumber,
          countries: const [
            Country(
              name: "France",
              nameTranslations: {"fr": "France", "en": "France"},
              flag: "🇫🇷",
              code: "FR",
              dialCode: "33",
              minLength: 9,
              maxLength: 9,
            ),
          ],
          onChanged: (phone) {
            onPhoneChanged(phone.completeNumber);
            onFieldChanged();
          },
        ),
      ],
    );
  }
}
