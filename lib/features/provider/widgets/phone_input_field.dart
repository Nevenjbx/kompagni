import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/countries.dart';

class PhoneInputField extends StatelessWidget {
  final String? phoneNumber;
  final ValueChanged<String> onChanged;

  const PhoneInputField({
    super.key,
    required this.phoneNumber,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return IntlPhoneField(
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
      onChanged: (phone) => onChanged(phone.completeNumber),
    );
  }
}
