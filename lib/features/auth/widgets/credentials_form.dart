import 'package:flutter/material.dart';

class CredentialsForm extends StatelessWidget {
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final bool obscurePassword;
  final bool obscureConfirmPassword;
  final VoidCallback onTogglePassword;
  final VoidCallback onToggleConfirmPassword;
  final bool isProvider;
  final VoidCallback? onSubmit;

  const CredentialsForm({
    super.key,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.obscurePassword,
    required this.obscureConfirmPassword,
    required this.onTogglePassword,
    required this.onToggleConfirmPassword,
    required this.isProvider,
    this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: emailController,
          decoration: const InputDecoration(
            labelText: 'Email',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.email),
          ),
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: passwordController,
          decoration: InputDecoration(
            labelText: 'Mot de passe',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.lock),
            suffixIcon: IconButton(
              icon: Icon(
                obscurePassword ? Icons.visibility : Icons.visibility_off,
              ),
              onPressed: onTogglePassword,
            ),
          ),
          obscureText: obscurePassword,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: confirmPasswordController,
          decoration: InputDecoration(
            labelText: 'Confirmer le mot de passe',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(
                obscureConfirmPassword
                    ? Icons.visibility
                    : Icons.visibility_off,
              ),
              onPressed: onToggleConfirmPassword,
            ),
          ),
          obscureText: obscureConfirmPassword,
          textInputAction:
              isProvider ? TextInputAction.next : TextInputAction.done,
          onSubmitted: isProvider ? null : (_) => onSubmit?.call(),
        ),
      ],
    );
  }
}
