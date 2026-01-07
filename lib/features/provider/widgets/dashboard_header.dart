import 'package:flutter/material.dart';
import '../../../shared/models/provider.dart' as models;
import '../screens/edit_account_screen.dart';

class DashboardHeader extends StatelessWidget {
  final models.Provider? profile;

  const DashboardHeader({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: profile == null
            ? const CircularProgressIndicator()
            : ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context)
                      .push(
                    MaterialPageRoute(
                      builder: (context) =>
                          EditAccountScreen(provider: profile!),
                    ),
                  )
                      .then((result) {
                    if (result == true) {
                      // Refresh will happen via provider
                    }
                  });
                },
                icon: const Icon(Icons.edit),
                label: const Text('Éditer mon compte'),
              ),
      ),
    );
  }
}
