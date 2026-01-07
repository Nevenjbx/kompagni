import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/service.dart';
import 'service_card.dart';
import 'add_service_card.dart';

class ServicesCarousel extends ConsumerWidget {
  final List<Service> services;
  final VoidCallback onRefresh;

  const ServicesCarousel({
    super.key,
    required this.services,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            'Mes Services',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(
          height: 160,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: services.length + 1, // +1 for add card
            itemBuilder: (context, index) {
              // Render "Add Card" at the end
              if (index == services.length) {
                return AddServiceCard(onRefresh: onRefresh);
              }

              return ServiceCard(
                service: services[index],
                onRefresh: onRefresh,
              );
            },
          ),
        ),
      ],
    );
  }
}
