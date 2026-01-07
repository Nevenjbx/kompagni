import 'package:flutter/material.dart';
import '../../../shared/services/address_service.dart';
import 'address_input.dart';

class ProviderInfoForm extends StatelessWidget {
  final TextEditingController businessNameController;
  final TextEditingController descriptionController;
  final TextEditingController addressController;
  final TextEditingController addressComplementController;
  final TextEditingController cityController;
  final TextEditingController postalCodeController;
  final AddressService addressService;
  final void Function(AddressResult) onAddressSelected;
  final VoidCallback onSubmit;

  const ProviderInfoForm({
    super.key,
    required this.businessNameController,
    required this.descriptionController,
    required this.addressController,
    required this.addressComplementController,
    required this.cityController,
    required this.postalCodeController,
    required this.addressService,
    required this.onAddressSelected,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Informations Prestataire',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: businessNameController,
          decoration: const InputDecoration(
            labelText: 'Nom de l\'entreprise',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.business),
          ),
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: descriptionController,
          decoration: const InputDecoration(
            labelText: 'Description',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.description),
          ),
          maxLines: 3,
          textInputAction: TextInputAction.newline,
        ),
        const SizedBox(height: 16),
        AddressInput(
          controller: addressController,
          addressService: addressService,
          onSelected: onAddressSelected,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: addressComplementController,
          decoration: const InputDecoration(
            labelText: 'Complément d\'adresse (optionnel)',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.add_location_alt),
          ),
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: cityController,
                decoration: const InputDecoration(
                  labelText: 'Ville',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_city),
                ),
                textInputAction: TextInputAction.next,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                controller: postalCodeController,
                decoration: const InputDecoration(
                  labelText: 'Code postal',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.map),
                ),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => onSubmit(),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
