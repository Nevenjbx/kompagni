import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/countries.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import '../../../shared/services/address_service.dart';
import '../services/auth_service.dart';
import '../../../shared/services/user_service.dart';
import '../../client/screens/home_client.dart';
import '../../client/screens/add_pet_screen.dart';
import '../../provider/screens/provider_dashboard_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
  final AddressService _addressService = AddressService();
  
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  
  // Provider fields
  final _businessNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _addressComplementController = TextEditingController();
  final _cityController = TextEditingController();
  final _postalCodeController = TextEditingController();
  
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
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      final confirmPassword = _confirmPasswordController.text.trim();

      if (email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
        throw const AuthException('Veuillez remplir tous les champs');
      }

      if (password != confirmPassword) {
        throw const AuthException('Les mots de passe ne correspondent pas');
      }

      // Collect data
      final firstName = _firstNameController.text.trim();
      final lastName = _lastNameController.text.trim();
      
      if (firstName.isEmpty || lastName.isEmpty) {
        throw const AuthException('Veuillez entrer votre prénom et votre nom');
      }

      final name = '$firstName $lastName';
      
      Map<String, dynamic>? providerProfile;
      if (_isProvider) {
        final businessName = _businessNameController.text.trim();
        final addressLine1 = _addressController.text.trim();
        final addressLine2 = _addressComplementController.text.trim();
        final city = _cityController.text.trim();
        final postalCode = _postalCodeController.text.trim();
        
        if (businessName.isEmpty || addressLine1.isEmpty || city.isEmpty || postalCode.isEmpty) {
          throw const AuthException('Veuillez remplir tous les détails du prestataire');
        }

        final fullAddress = addressLine2.isNotEmpty ? '$addressLine1, $addressLine2' : addressLine1;

        providerProfile = {
          'businessName': businessName,
          'description': _descriptionController.text.trim(),
          'address': fullAddress,
          'city': city,
          'postalCode': postalCode,
          'latitude': _latitude,
          'longitude': _longitude,
        };
      }

      final response = await _authService.signUpEmailPassword(
        email, 
        password,
        data: {
          'role': _isProvider ? 'PROVIDER' : 'CLIENT',
          'full_name': name, // Storing name in metadata as well
        },
      );

      if (mounted) {
        // If email confirmation is off, we might have a session immediately
        if (response.session != null) {
          // Sync user role with backend
          await _userService.syncUser(
            role: _isProvider ? 'PROVIDER' : 'CLIENT',
            name: name,
            phoneNumber: _phoneNumber,
            providerProfile: providerProfile,
            tags: _isProvider ? _selectedTags : null,
          );

          if (mounted) {
            if (_isProvider) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (context) => const ProviderDashboardScreen(),
                ),
                (route) => false,
              );
            } else {
              // For Clients: Show popup to add pet
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => AlertDialog(
                  title: const Text('Bienvenue sur Kompagni !'),
                  content: const Text('Voulez-vous ajouter un animal de compagnie maintenant ?'),
                  actions: [
                    TextButton(
                      onPressed: () {
                        // Skip: Go to Home
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (context) => const HomeClientScreen(),
                          ),
                          (route) => false,
                        );
                      },
                      child: const Text('Plus tard'),
                    ),
                    FilledButton(
                      onPressed: () {
                        // Add: Go to Home (base) then Add Pet
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (context) => const HomeClientScreen(),
                          ),
                          (route) => false,
                        );
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const AddPetScreen(),
                          ),
                        );
                      },
                      child: const Text('Ajouter'),
                    ),
                  ],
                ),
              );
            }
          }
        } else {
          // Otherwise, ask user to confirm email
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Compte créé ! Veuillez vérifier votre email pour confirmer.'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(); // Go back to login
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
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  color: Colors.red.shade100,
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red.shade900),
                    textAlign: TextAlign.center,
                  ),
                ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _lastNameController,
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
                      controller: _firstNameController,
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
                      "sk": "Francúzsko",
                      "se": "Frankriika",
                      "pl": "Francja",
                      "no": "Frankrike",
                      "ja": "フランス",
                      "it": "Francia",
                      "zh": "法国",
                      "nl": "Frankrijk",
                      "de": "Frankreich",
                      "fr": "France",
                      "es": "Francia",
                      "en": "France",
                      "pt_BR": "França",
                      "sr-Cyrl": "Француска",
                      "sr-Latn": "Francuska",
                      "zh_TW": "法國",
                      "tr": "Fransa",
                      "ro": "Franța",
                      "ar": "فرنسا",
                      "fa": "فرانسه",
                      "yue": "法國"
                    },
                    flag: "🇫🇷",
                    code: "FR",
                    dialCode: "33",
                    minLength: 9,
                    maxLength: 9,
                  ),
                ],
                onChanged: (phone) {
                  _phoneNumber = phone.completeNumber;
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _emailController,
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
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Mot de passe',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _confirmPasswordController,
                decoration: InputDecoration(
                  labelText: 'Confirmer le mot de passe',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),
                ),
                obscureText: _obscureConfirmPassword,
                textInputAction: _isProvider ? TextInputAction.next : TextInputAction.done,
                onSubmitted: _isProvider ? null : (_) => _signUp(),
              ),
              const SizedBox(height: 16),
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
              if (_isProvider) ...[
                const SizedBox(height: 16),
                const Text('Informations Prestataire', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(
                  controller: _businessNameController,
                  decoration: const InputDecoration(
                    labelText: 'Nom de l\'entreprise',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.business),
                  ),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _descriptionController,
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
                  controller: _addressController,
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
                    return await _addressService.searchAddress(pattern);
                  },
                  itemBuilder: (context, suggestion) {
                    return ListTile(
                      leading: const Icon(Icons.location_on),
                      title: Text(suggestion.displayName),
                    );
                  },
                  onSelected: (suggestion) {
                    _addressController.text = suggestion.street;
                    _cityController.text = suggestion.city;
                    _postalCodeController.text = suggestion.postalCode;
                    setState(() {
                      _latitude = suggestion.lat;
                      _longitude = suggestion.lon;
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _addressComplementController,
                  decoration: const InputDecoration(
                    labelText: 'Complément d\'adresse (batiment, etc.) Optionnel',
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
                        controller: _cityController,
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
                        controller: _postalCodeController,
                        decoration: const InputDecoration(
                          labelText: 'Code postal',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.map),
                        ),
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _signUp(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('Services proposés (Tags)', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8.0,
                  runSpacing: 4.0,
                  children: _availableTags.map((tag) {
                    final isSelected = _selectedTags.contains(tag);
                    return FilterChip(
                      label: Text(tag),
                      selected: isSelected,
                      onSelected: (bool selected) {
                        setState(() {
                          if (selected) {
                            _selectedTags.add(tag);
                          } else {
                            _selectedTags.remove(tag);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _signUp,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('S\'inscrire'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
