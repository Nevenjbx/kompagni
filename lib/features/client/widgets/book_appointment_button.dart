import 'package:flutter/material.dart';
import '../screens/provider_list_screen.dart';

class BookAppointmentButton extends StatelessWidget {
  final VoidCallback onRefresh;

  const BookAppointmentButton({super.key, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: () {
          Navigator.of(context)
              .push(
            MaterialPageRoute(
              builder: (context) => const ProviderListScreen(),
            ),
          )
              .then((_) => onRefresh());
        },
        child: const Text('Prendre rendez-vous'),
      ),
    );
  }
}
