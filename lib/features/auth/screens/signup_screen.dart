import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/services/address_service.dart';
import '../providers/auth_provider.dart';
import '../../../shared/repositories/user_repository.dart';
import '../../../shared/repositories/impl/user_repository_impl.dart'; // For userRepositoryProvider
import '../widgets/personal_info_form.dart';
import '../widgets/credentials_form.dart';
import '../widgets/provider_info_form.dart';
import '../widgets/tags_selector.dart';
import '../widgets/form_submit_button.dart';
import '../widgets/error_banner.dart';
import '../../../core/errors/app_exception.dart' as app_errors;

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  // AuthService accessed via ref.read(authServiceProvider)
  final AddressService _addressService = AddressService();

  // Form controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();

  // Provider-specific controllers
  final _businessNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _addressComplementController = TextEditingController();
  final _cityController = TextEditingController();
  final _postalCodeController = TextEditingController();

  // State
  String? _phoneNumber;
  double? _latitude;
  double? _longitude;
  bool _isLoading = false;
  bool _isProvider = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorMessage;

  static const List<String> _availableTags = [
    'Toiletteur',
    'Vétérinaire',
    'Pension',
    'Promenade',
    'Chien',
    'Chat',
    'Éducation',
    'Garde a domicile'
  ];
  final List<String> _selectedTags = [];

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _businessNameController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _addressComplementController.dispose();
    _cityController.dispose();
    _postalCodeController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Validate inputs
      _validateInputs();

      // Collect data
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      final firstName = _firstNameController.text.trim();
      final lastName = _lastNameController.text.trim();
      final name = '$firstName $lastName';

      // Build provider profile if needed
      Map<String, dynamic>? providerProfile;
      if (_isProvider) {
        providerProfile = _buildProviderProfile();
      }

      // Sign up with Supabase
      final authService = ref.read(authServiceProvider);
      final response = await authService.signUpEmailPassword(
        email,
        password,
        data: {
          'role': _isProvider ? 'PROVIDER' : 'CLIENT',
          'full_name': name,
          'first_name': firstName,
          'last_name': lastName,
        },
      );

      // Sync with backend
      if (response.session != null) {
        final userRepository = ref.read(userRepositoryProvider);
        await userRepository.syncUser(
          role: _isProvider ? 'PROVIDER' : 'CLIENT',
          firstName: firstName,
          lastName: lastName,
          phoneNumber: _phoneNumber,
          providerProfile: providerProfile,
          tags: _isProvider ? _selectedTags : null,
        );
      }

      if (mounted) {
        if (response.session != null) {
          // GoRouter authentication listener will handle redirect
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Compte créé avec succès !'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          // Email confirmation required
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Compte créé ! Veuillez vérifier votre email pour confirmer.',
              ),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop();
        }
      }
    } on app_errors.AuthException catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
    } on AuthException catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Une erreur inattendue est survenue: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _validateInputs() {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();

    if (email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      throw const app_errors.AuthException(message: 'Veuillez remplir tous les champs');
    }

    if (password != confirmPassword) {
      throw const app_errors.AuthException(message: 'Les mots de passe ne correspondent pas');
    }

    if (firstName.isEmpty || lastName.isEmpty) {
      throw const app_errors.AuthException(message: 'Veuillez entrer votre prénom et votre nom');
    }

    if (_isProvider) {
      final businessName = _businessNameController.text.trim();
      final address = _addressController.text.trim();
      final city = _cityController.text.trim();
      final postalCode = _postalCodeController.text.trim();

      if (businessName.isEmpty ||
          address.isEmpty ||
          city.isEmpty ||
          postalCode.isEmpty) {
        throw const app_errors.AuthException(message: 'Veuillez remplir tous les détails du prestataire');
      }
    }
  }

  Map<String, dynamic> _buildProviderProfile() {
    final addressLine1 = _addressController.text.trim();
    final addressLine2 = _addressComplementController.text.trim();
    final fullAddress =
        addressLine2.isNotEmpty ? '$addressLine1, $addressLine2' : addressLine1;

    return {
      'businessName': _businessNameController.text.trim(),
      'description': _descriptionController.text.trim(),
      'address': fullAddress,
      'city': _cityController.text.trim(),
      'postalCode': _postalCodeController.text.trim(),
      'latitude': _latitude,
      'longitude': _longitude,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Créer un compte')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_errorMessage != null)
                ErrorBanner(message: _errorMessage!),

              // Personal Info
              PersonalInfoForm(
                firstNameController: _firstNameController,
                lastNameController: _lastNameController,
                phoneNumber: _phoneNumber,
                onPhoneChanged: (phone) {
                  _phoneNumber = phone;
                },
              ),
              const SizedBox(height: 16),

              // Credentials
              CredentialsForm(
                emailController: _emailController,
                passwordController: _passwordController,
                confirmPasswordController: _confirmPasswordController,
                obscurePassword: _obscurePassword,
                obscureConfirmPassword: _obscureConfirmPassword,
                onTogglePassword: () {
                  setState(() => _obscurePassword = !_obscurePassword);
                },
                onToggleConfirmPassword: () {
                  setState(
                      () => _obscureConfirmPassword = !_obscureConfirmPassword);
                },
                isProvider: _isProvider,
                onSubmit: _isProvider ? null : _signUp,
              ),
              const SizedBox(height: 16),

              // Provider Toggle
              CheckboxListTile(
                title: const Text('Je suis un prestataire'),
                value: _isProvider,
                onChanged: (bool? value) {
                  setState(() {
                    _isProvider = value ?? false;
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),

              // Provider Section (conditional)
              if (_isProvider) ...[
                const SizedBox(height: 16),
                ProviderInfoForm(
                  businessNameController: _businessNameController,
                  descriptionController: _descriptionController,
                  addressController: _addressController,
                  addressComplementController: _addressComplementController,
                  cityController: _cityController,
                  postalCodeController: _postalCodeController,
                  addressService: _addressService,
                  onAddressSelected: (result) {
                    _addressController.text = result.street;
                    _cityController.text = result.city;
                    _postalCodeController.text = result.postalCode;
                    setState(() {
                      _latitude = result.lat;
                      _longitude = result.lon;
                    });
                  },
                  onSubmit: _signUp,
                ),
                const SizedBox(height: 16),
                TagsSelector(
                  availableTags: _availableTags,
                  selectedTags: _selectedTags,
                  onTagToggled: (tag, selected) {
                    setState(() {
                      if (selected) {
                        _selectedTags.add(tag);
                      } else {
                        _selectedTags.remove(tag);
                      }
                    });
                  },
                ),
              ],

              const SizedBox(height: 24),

              // Submit Button
              FormSubmitButton(
                isLoading: _isLoading,
                onPressed: _signUp,
                label: 'S\'inscrire',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
