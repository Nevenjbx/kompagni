import 'package:flutter/material.dart';
import '../../../shared/models/provider.dart' as models;

class ProviderInfoSection extends StatelessWidget {
  final models.Provider provider;

  const ProviderInfoSection({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          provider.description,
          style: const TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 8),
        Text(
          '${provider.address}, ${provider.city} ${provider.postalCode}',
          style: const TextStyle(color: Colors.grey),
        ),
      ],
    );
  }
}
