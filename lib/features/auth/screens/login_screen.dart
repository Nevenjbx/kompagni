import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/auth_provider.dart';
import '../../../shared/repositories/user_repository.dart';
import '../../../shared/repositories/impl/user_repository_impl.dart'; // For userRepositoryProvider
import 'signup_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscureText = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      if (email.isEmpty || password.isEmpty) {
        throw const AuthException('Veuillez remplir tous les champs');
      }

      final authService = ref.read(authServiceProvider);
      await authService.signInEmailPassword(email, password);

      // Fetch user profile from backend
      final userRepository = ref.read(userRepositoryProvider);
      Map<String, dynamic>? userProfile = await userRepository.getCurrentUser();

      // If profile doesn't exist locally (data mismatch), try to sync
      if (userProfile == null) {
        final user = authService.currentUser;
        final metadataRole = user?.userMetadata?['role'];
        final roleToSync = metadataRole?.toString() ?? 'CLIENT';

        await userRepository.syncUser(role: roleToSync);
      }

      // Navigation handled by GoRouter's auth listener
    } on AuthException catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
    } catch (e) {
      debugPrint('Login Error: $e');
      setState(() {
        _errorMessage = 'Une erreur inattendue est survenue';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Connexion')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_errorMessage != null)
                _ErrorBanner(message: _errorMessage!),
              _EmailField(
                controller: _emailController,
                onSubmitted: (_) => FocusScope.of(context).nextFocus(),
              ),
              const SizedBox(height: 16),
              _PasswordField(
                controller: _passwordController,
                obscureText: _obscureText,
                onToggleVisibility: () {
                  setState(() {
                    _obscureText = !_obscureText;
                  });
                },
                onSubmitted: (_) => _signIn(),
              ),
              const SizedBox(height: 24),
              _LoginButton(
                isLoading: _isLoading,
                onPressed: _signIn,
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const SignUpScreen(),
                    ),
                  );
                },
                child: const Text('Créer un compte'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Error banner widget
class _ErrorBanner extends StatelessWidget {
  final String message;

  const _ErrorBanner({required this.message});

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

/// Email text field
class _EmailField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String>? onSubmitted;

  const _EmailField({
    required this.controller,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: const InputDecoration(
        labelText: 'Email',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.email),
      ),
      keyboardType: TextInputType.emailAddress,
      autofillHints: const [AutofillHints.email],
      textInputAction: TextInputAction.next,
      onSubmitted: onSubmitted,
    );
  }
}

/// Password text field
class _PasswordField extends StatelessWidget {
  final TextEditingController controller;
  final bool obscureText;
  final VoidCallback onToggleVisibility;
  final ValueChanged<String>? onSubmitted;

  const _PasswordField({
    required this.controller,
    required this.obscureText,
    required this.onToggleVisibility,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: 'Mot de passe',
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.lock),
        suffixIcon: IconButton(
          icon: Icon(
            obscureText ? Icons.visibility : Icons.visibility_off,
          ),
          onPressed: onToggleVisibility,
        ),
      ),
      obscureText: obscureText,
      textInputAction: TextInputAction.done,
      onSubmitted: onSubmitted,
    );
  }
}

/// Login button
class _LoginButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;

  const _LoginButton({
    required this.isLoading,
    required this.onPressed,
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
          : const Text('Se connecter'),
    );
  }
}
