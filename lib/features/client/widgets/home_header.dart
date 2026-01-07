import 'package:flutter/material.dart';
import '../screens/client_profile_screen.dart';

class HomeHeader extends StatelessWidget {
  final String displayName;
  final VoidCallback? onProfileTap;

  const HomeHeader({
    super.key,
    required this.displayName,
    this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Bonjour $displayName',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        IconButton(
          onPressed: onProfileTap ??
              () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ClientProfileScreen(),
                  ),
                );
              },
          icon: const CircleAvatar(
            child: Icon(Icons.person),
          ),
        ),
      ],
    );
  }
}
