import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dio/dio.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/countries.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import '../../../shared/services/address_service.dart';
import '../../../shared/services/user_service.dart';
import '../services/provider_service.dart';
import '../../../shared/models/provider.dart';
import 'manage_availability_screen.dart';

class EditAccountScreen extends StatefulWidget {
  final Provider provider;

  const EditAccountScreen({super.key, required this.provider});

  @override
  State<EditAccountScreen> createState() => _EditAccountScreenState();
}

class _EditAccountScreenState extends State<EditAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _providerService = ProviderService();
  final _userService = UserService();
  final _addressService = AddressService();
  bool _isLoading = false;

  late TextEditingController _businessNameController;
  late TextEditingController _descriptionController;
  late TextEditingController _addressController;
  late TextEditingController _cityController;
  late TextEditingController _postalCodeController;
  late TextEditingController _emailController;
  
  String? _phoneNumber;
  double? _latitude;
  double? _longitude;

  @override
  void initState() {
    super.initState();
    _businessNameController = TextEditingController(text: widget.provider.businessName);
    _descriptionController = TextEditingController(text: widget.provider.description);
    _addressController = TextEditingController(text: widget.provider.address);
    _cityController = TextEditingController(text: widget.provider.city);
    _postalCodeController = TextEditingController(text: widget.provider.postalCode);
    _emailController = TextEditingController(); // Will be populated by fetching user data.
    
    // Initialize lat/lon from provider if available
    _latitude = widget.provider.latitude;
    _longitude = widget.provider.longitude;
    
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final userData = await _userService.getCurrentUser();
      if (userData != null) {
        if (mounted) {
           setState(() {
             _emailController.text = userData['email'] ?? '';
             // Ensure _phoneNumber receives the data from backend
             if (userData['phoneNumber'] != null) {
                // Assuming format from backend is E.164 (e.g., +33123456789)
                // We'll set it as _initialPhoneNumber and let IntlPhoneField handle it via initialValue
                _phoneNumber = userData['phoneNumber'].toString();
             }
           });
        }
      }
    } catch (e) {
      // ignore silently
    }
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _postalCodeController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final updates = {
        'businessName': _businessNameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'address': _addressController.text.trim(),
        'city': _cityController.text.trim(),
        'postalCode': _postalCodeController.text.trim(),
        'latitude': _latitude,
        'longitude': _longitude,
      };
      
      // Update provider profile
      await _providerService.updateProfile(updates);

      // Update User details (Phone, Email, etc.)
      final userUpdates = <String, dynamic>{};
      
      if (_phoneNumber != null && _phoneNumber!.isNotEmpty) {
        userUpdates['phoneNumber'] = _phoneNumber;
      }
      
      final email = _emailController.text.trim();
      if (email.isNotEmpty) {
         userUpdates['email'] = email;
      }
      
      if (userUpdates.isNotEmpty) {
        await _userService.updateUser(userUpdates);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil mis à jour !')),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      String errorMessage = 'Erreur inconnu: $e';
      if (e is DioException) {
         errorMessage = 'Erreur API (${e.response?.statusCode}): ${e.response?.data ?? e.message}';
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Copier',
              onPressed: () {
                // Clipboard.setData(ClipboardData(text: errorMessage)); 
              },
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modifier mon compte'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Informations Générales', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _businessNameController,
                      decoration: const InputDecoration(
                        labelText: 'Nom de l\'entreprise',
                        prefixIcon: Icon(Icons.business),
                         border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value == null || value.isEmpty ? 'Champ requis' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        prefixIcon: Icon(Icons.description),
                         border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),
                    
                    const Text('Coordonnées', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email),
                         border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    IntlPhoneField(
                      key: Key(_phoneNumber ?? 'phone_field'),
                      decoration: const InputDecoration(
                        labelText: 'Numéro de téléphone',
                        border: OutlineInputBorder(),
                      ),
                      initialCountryCode: 'FR',
                      initialValue: _phoneNumber, // This might need country code stripping if initialCountryCode is set, but library tries to handle parsing.
                      // If key is used, it re-inits with initialValue.
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
                    // Address Section with Autocomplete
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
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _postalCodeController,
                            decoration: const InputDecoration(
                              labelText: 'Code Postal',
                               border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _cityController,
                            decoration: const InputDecoration(
                              labelText: 'Ville',
                               border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                     const SizedBox(height: 32),
                     
                     // Availability Link
                     OutlinedButton.icon(
                        icon: const Icon(Icons.schedule),
                        label: const Text('Gérer mes horaires d\'ouverture'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                          alignment: Alignment.centerLeft,
                          textStyle: const TextStyle(fontSize: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (context) => const ManageAvailabilityScreen()),
                          );
                        },
                     ),
                     
                     const SizedBox(height: 32),
                     
                     ElevatedButton(
                       onPressed: _save,
                       style: ElevatedButton.styleFrom(
                         padding: const EdgeInsets.symmetric(vertical: 16),
                         textStyle: const TextStyle(fontSize: 18),
                       ),
                       child: const Text('Enregistrer les modifications'),
                     ),
                     
                     const SizedBox(height: 48),
                     const Divider(),
                     const SizedBox(height: 16),
                     
                     Center(
                       child: TextButton.icon(
                         onPressed: _deleteAccount,
                         icon: const Icon(Icons.delete_forever, color: Colors.red),
                         label: const Text(
                           'Supprimer mon compte',
                           style: TextStyle(color: Colors.red),
                         ),
                         style: TextButton.styleFrom(
                           padding: const EdgeInsets.all(16),
                         ),
                       ),
                     ),
                  ],
                ),
              ),
            ),
    );
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer mon compte'),
        content: const Text(
          'Êtes-vous sûr de vouloir supprimer votre compte ?\n\n'
          'Cette action est irréversible et supprimera toutes vos données.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer définitivement'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      await _userService.deleteAccount();
      
      // Sign out from Supabase
      await Supabase.instance.client.auth.signOut();

      if (mounted) {
        // Navigate to initial route (Login/Home) and remove all previous routes
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la suppression: $e')),
        );
      }
      setState(() => _isLoading = false);
    }
  }
}
