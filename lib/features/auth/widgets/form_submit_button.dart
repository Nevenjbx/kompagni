import 'package:flutter/material.dart';

class FormSubmitButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback? onPressed;
  final String label;

  const FormSubmitButton({
    super.key,
    required this.isLoading,
    required this.onPressed,
    this.label = 'S\'inscrire',
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(label),
    );
  }
}
