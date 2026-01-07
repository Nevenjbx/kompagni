import 'package:flutter/material.dart';
import '../screens/add_service_screen.dart';

class AddServiceCard extends StatelessWidget {
  final VoidCallback onRefresh;

  const AddServiceCard({super.key, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      child: Card(
        color: Colors.blue.shade50,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          onTap: () {
            Navigator.of(context)
                .push(
              MaterialPageRoute(
                builder: (context) => const AddServiceScreen(),
              ),
            )
                .then((_) => onRefresh());
          },
          borderRadius: BorderRadius.circular(16),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_circle, size: 40, color: Colors.blue),
              SizedBox(height: 8),
              Text(
                'Ajouter',
                style:
                    TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
