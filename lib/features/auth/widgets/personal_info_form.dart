import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/countries.dart';

class PersonalInfoForm extends StatelessWidget {
  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final String? phoneNumber;
  final ValueChanged<String?> onPhoneChanged;

  const PersonalInfoForm({
    super.key,
    required this.firstNameController,
    required this.lastNameController,
    required this.phoneNumber,
    required this.onPhoneChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: lastNameController,
                decoration: const InputDecoration(
                  labelText: 'Nom',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                textInputAction: TextInputAction.next,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                controller: firstNameController,
                decoration: const InputDecoration(
                  labelText: 'Prénom',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_outline),
                ),
                textInputAction: TextInputAction.next,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        IntlPhoneField(
          decoration: const InputDecoration(
            labelText: 'Numéro de téléphone',
            border: OutlineInputBorder(),
          ),
          initialCountryCode: 'FR',
          countries: const [
            Country(
              name: "France",
              nameTranslations: {
                "fr": "France",
                "en": "France",
              },
              flag: "🇫🇷",
              code: "FR",
              dialCode: "33",
              minLength: 9,
              maxLength: 9,
            ),
          ],
          onChanged: (phone) {
            onPhoneChanged(phone.completeNumber);
          },
        ),
      ],
    );
  }
}
