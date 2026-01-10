import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../shared/models/appointment.dart';

/// Quick popup displaying client information
class ClientInfoPopup extends StatelessWidget {
  final AppointmentClient client;

  const ClientInfoPopup({super.key, required this.client});

  /// Show the popup as a dialog
  static Future<void> show(BuildContext context, AppointmentClient client) {
    return showDialog(
      context: context,
      builder: (context) => ClientInfoPopup(client: client),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Colors.blue,
            child: Icon(Icons.person, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              client.displayName,
              style: const TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Email
          if (client.email.isNotEmpty)
            _ContactRow(
              icon: Icons.email,
              label: 'Email',
              value: client.email,
              onTap: () => _launchEmail(client.email),
            ),

          // Phone
          if (client.phoneNumber != null && client.phoneNumber!.isNotEmpty)
            _ContactRow(
              icon: Icons.phone,
              label: 'Téléphone',
              value: client.phoneNumber!,
              onTap: () => _launchPhone(client.phoneNumber!),
            ),
        ],
      ),
      actions: [
        // Quick call button
        if (client.phoneNumber != null && client.phoneNumber!.isNotEmpty)
          TextButton.icon(
            onPressed: () => _launchPhone(client.phoneNumber!),
            icon: const Icon(Icons.phone),
            label: const Text('Appeler'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Fermer'),
        ),
      ],
    );
  }

  Future<void> _launchEmail(String email) async {
    final uri = Uri.parse('mailto:$email');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _launchPhone(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  const _ContactRow({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: Colors.grey.shade600),
      title: Text(
        label,
        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
      ),
      subtitle: Text(
        value,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
      onTap: onTap,
      trailing: onTap != null
          ? Icon(Icons.open_in_new, size: 16, color: Colors.grey.shade400)
          : null,
    );
  }
}
