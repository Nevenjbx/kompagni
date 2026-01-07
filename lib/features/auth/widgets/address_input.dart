import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import '../../../shared/services/address_service.dart';

class AddressInput extends StatelessWidget {
  final TextEditingController controller;
  final AddressService addressService;
  final void Function(AddressResult) onSelected;
  final String label;
  final IconData prefixIcon;

  const AddressInput({
    super.key,
    required this.controller,
    required this.addressService,
    required this.onSelected,
    this.label = 'Adresse',
    this.prefixIcon = Icons.location_on,
  });

  @override
  Widget build(BuildContext context) {
    return TypeAheadField<AddressResult>(
      controller: controller,
      builder: (context, controller, focusNode) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
            prefixIcon: Icon(prefixIcon),
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
      onSelected: onSelected,
    );
  }
}
