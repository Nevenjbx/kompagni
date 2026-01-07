import 'package:flutter/material.dart';

class ErrorBanner extends StatelessWidget {
  final String message;

  const ErrorBanner({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 16),
      color: Colors.red.shade100,
      child: Text(
        message,
        style: TextStyle(color: Colors.red.shade900),
        textAlign: TextAlign.center,
      ),
    );
  }
}
