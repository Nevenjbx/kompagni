import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import '../../../shared/services/address_service.dart';

class AddressFormSection extends StatelessWidget {
  final TextEditingController addressController;
  final TextEditingController cityController;
  final TextEditingController postalCodeController;
  final AddressService addressService;
  final void Function(AddressResult) onAddressSelected;

  const AddressFormSection({
    super.key,
    required this.addressController,
    required this.cityController,
    required this.postalCodeController,
    required this.addressService,
    required this.onAddressSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TypeAheadField<AddressResult>(
          controller: addressController,
          builder: (context, controller, focusNode) {
            return TextField(
              controller: controller,
              focusNode: focusNode,
              decoration: const InputDecoration(
                labelText: 'Adresse',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
            );
          },
          suggestionsCallback: (pattern) async {
            return await addressService.searchAddress(pattern);
          },
          itemBuilder: (context, suggestion) {
            return ListTile(
              leading: const Icon(Icons.location_on),
              title: Text(suggestion.displayName),
            );
          },
          onSelected: onAddressSelected,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: postalCodeController,
                decoration: const InputDecoration(
                  labelText: 'Code Postal',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: cityController,
                decoration: const InputDecoration(
                  labelText: 'Ville',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
