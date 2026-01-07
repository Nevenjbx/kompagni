import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/countries.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import '../../../shared/services/address_service.dart';
import '../services/auth_service.dart';
import '../../../shared/repositories/impl/user_repository_impl.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final AuthService _authService = AuthService();
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

  final List<String> _availableTags = [
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
      final response = await _authService.signUpEmailPassword(
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
          name: name,
          phoneNumber: _phoneNumber,
          providerProfile: providerProfile,
          tags: _isProvider ? _selectedTags : null,
        );
      }

      if (mounted) {
        if (response.session != null) {
          // GoRouter authentication listener will handle redirect
          // Show success feedback
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
    } on AuthException catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
    } catch (e) {
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

  void _validateInputs() {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();

    if (email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      throw const AuthException('Veuillez remplir tous les champs');
    }

    if (password != confirmPassword) {
      throw const AuthException('Les mots de passe ne correspondent pas');
    }

    if (firstName.isEmpty || lastName.isEmpty) {
      throw const AuthException('Veuillez entrer votre prénom et votre nom');
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
        throw const AuthException(
          'Veuillez remplir tous les détails du prestataire',
        );
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
                _ErrorBanner(message: _errorMessage!),

              // Personal Info Section
              _PersonalInfoSection(
                firstNameController: _firstNameController,
                lastNameController: _lastNameController,
                phoneNumber: _phoneNumber,
                onPhoneChanged: (phone) {
                  _phoneNumber = phone;
                },
              ),
              const SizedBox(height: 16),

              // Credentials Section
              _CredentialsSection(
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
                _ProviderInfoSection(
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
                _TagsSelector(
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
              _SubmitButton(
                isLoading: _isLoading,
                onPressed: _signUp,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// EXTRACTED WIDGETS
// ============================================================================

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

/// Personal info section (name, phone)
class _PersonalInfoSection extends StatelessWidget {
  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final String? phoneNumber;
  final ValueChanged<String?> onPhoneChanged;

  const _PersonalInfoSection({
    required this.firstNameController,
    required this.lastNameController,
    required this.phoneNumber,
    required this.onPhoneChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: lastNameController,
                decoration: const InputDecoration(
                  labelText: 'Nom',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                textInputAction: TextInputAction.next,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                controller: firstNameController,
                decoration: const InputDecoration(
                  labelText: 'Prénom',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_outline),
                ),
                textInputAction: TextInputAction.next,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        IntlPhoneField(
          decoration: const InputDecoration(
            labelText: 'Numéro de téléphone',
            border: OutlineInputBorder(),
          ),
          initialCountryCode: 'FR',
          countries: const [
            Country(
              name: "France",
              nameTranslations: {
                "fr": "France",
                "en": "France",
              },
              flag: "🇫🇷",
              code: "FR",
              dialCode: "33",
              minLength: 9,
              maxLength: 9,
            ),
          ],
          onChanged: (phone) {
            onPhoneChanged(phone.completeNumber);
          },
        ),
      ],
    );
  }
}

/// Credentials section (email, password)
class _CredentialsSection extends StatelessWidget {
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final bool obscurePassword;
  final bool obscureConfirmPassword;
  final VoidCallback onTogglePassword;
  final VoidCallback onToggleConfirmPassword;
  final bool isProvider;
  final VoidCallback? onSubmit;

  const _CredentialsSection({
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

/// Provider info section
class _ProviderInfoSection extends StatelessWidget {
  final TextEditingController businessNameController;
  final TextEditingController descriptionController;
  final TextEditingController addressController;
  final TextEditingController addressComplementController;
  final TextEditingController cityController;
  final TextEditingController postalCodeController;
  final AddressService addressService;
  final void Function(AddressResult) onAddressSelected;
  final VoidCallback onSubmit;

  const _ProviderInfoSection({
    required this.businessNameController,
    required this.descriptionController,
    required this.addressController,
    required this.addressComplementController,
    required this.cityController,
    required this.postalCodeController,
    required this.addressService,
    required this.onAddressSelected,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Informations Prestataire',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: businessNameController,
          decoration: const InputDecoration(
            labelText: 'Nom de l\'entreprise',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.business),
          ),
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: descriptionController,
          decoration: const InputDecoration(
            labelText: 'Description',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.description),
          ),
          maxLines: 3,
          textInputAction: TextInputAction.newline,
        ),
        const SizedBox(height: 16),
        TypeAheadField<AddressResult>(
          controller: addressController,
          builder: (context, controller, focusNode) {
            return TextField(
              controller: controller,
              focusNode: focusNode,
              decoration: const InputDecoration(
                labelText: 'Adresse',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
            );
          },
          suggestionsCallback: (pattern) async {
            return await addressService.searchAddress(pattern);
          },
          itemBuilder: (context, suggestion) {
            return ListTile(
              leading: const Icon(Icons.location_on),
              title: Text(suggestion.displayName),
            );
          },
          onSelected: onAddressSelected,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: addressComplementController,
          decoration: const InputDecoration(
            labelText: 'Complément d\'adresse (optionnel)',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.add_location_alt),
          ),
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: cityController,
                decoration: const InputDecoration(
                  labelText: 'Ville',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_city),
                ),
                textInputAction: TextInputAction.next,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                controller: postalCodeController,
                decoration: const InputDecoration(
                  labelText: 'Code postal',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.map),
                ),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => onSubmit(),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Tags selector widget
class _TagsSelector extends StatelessWidget {
  final List<String> availableTags;
  final List<String> selectedTags;
  final void Function(String tag, bool selected) onTagToggled;

  const _TagsSelector({
    required this.availableTags,
    required this.selectedTags,
    required this.onTagToggled,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Services proposés (Tags)',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8.0,
          runSpacing: 4.0,
          children: availableTags.map((tag) {
            final isSelected = selectedTags.contains(tag);
            return FilterChip(
              label: Text(tag),
              selected: isSelected,
              onSelected: (bool selected) => onTagToggled(tag, selected),
            );
          }).toList(),
        ),
      ],
    );
  }
}

/// Submit button
class _SubmitButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;

  const _SubmitButton({
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
          : const Text('S\'inscrire'),
    );
  }
}
