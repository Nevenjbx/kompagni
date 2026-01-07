import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/countries.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import '../../../core/errors/app_exception.dart';
import '../../../shared/services/address_service.dart';
import '../../../shared/models/provider.dart' as models;
import '../../../shared/repositories/impl/user_repository_impl.dart';
import '../../../shared/repositories/impl/provider_repository_impl.dart';
import '../../../shared/providers/provider_profile_provider.dart';
import '../../auth/providers/auth_provider.dart';
import 'manage_availability_screen.dart';

class EditAccountScreen extends ConsumerStatefulWidget {
  final models.Provider provider;

  const EditAccountScreen({super.key, required this.provider});

  @override
  ConsumerState<EditAccountScreen> createState() => _EditAccountScreenState();
}

class _EditAccountScreenState extends ConsumerState<EditAccountScreen> {
  final _formKey = GlobalKey<FormState>();
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
    _businessNameController =
        TextEditingController(text: widget.provider.businessName);
    _descriptionController =
        TextEditingController(text: widget.provider.description);
    _addressController = TextEditingController(text: widget.provider.address);
    _cityController = TextEditingController(text: widget.provider.city);
    _postalCodeController =
        TextEditingController(text: widget.provider.postalCode);
    _emailController = TextEditingController();

    _latitude = widget.provider.latitude;
    _longitude = widget.provider.longitude;

    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final userRepository = ref.read(userRepositoryProvider);
      final userData = await userRepository.getCurrentUser();
      if (userData != null && mounted) {
        setState(() {
          _emailController.text = userData['email'] ?? '';
          if (userData['phoneNumber'] != null) {
            _phoneNumber = userData['phoneNumber'].toString();
          }
        });
      }
    } catch (e) {
      // Ignore silently
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
      final providerRepository = ref.read(providerRepositoryProvider);
      await providerRepository.updateProfile(updates);

      // Update User details
      final userUpdates = <String, dynamic>{};

      if (_phoneNumber != null && _phoneNumber!.isNotEmpty) {
        userUpdates['phoneNumber'] = _phoneNumber;
      }

      final email = _emailController.text.trim();
      if (email.isNotEmpty) {
        userUpdates['email'] = email;
      }

      if (userUpdates.isNotEmpty) {
        final userRepository = ref.read(userRepositoryProvider);
        await userRepository.updateUser(userUpdates);
      }

      // Invalidate provider profile to refresh
      ref.invalidate(providerProfileProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil mis à jour !')),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      String errorMessage = 'Erreur: $e';
      if (e is AppException) {
        errorMessage = e.message;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
      final userRepository = ref.read(userRepositoryProvider);
      await userRepository.deleteAccount();

      // Sign out
      final authService = ref.read(authServiceProvider);
      await authService.signOut();

      if (mounted) {
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
                    // General Info Section
                    _SectionTitle(title: 'Informations Générales'),
                    const SizedBox(height: 16),
                    _BusinessNameField(controller: _businessNameController),
                    const SizedBox(height: 16),
                    _DescriptionField(controller: _descriptionController),
                    const SizedBox(height: 24),

                    // Contact Section
                    _SectionTitle(title: 'Coordonnées'),
                    const SizedBox(height: 16),
                    _EmailField(controller: _emailController),
                    const SizedBox(height: 16),
                    _PhoneField(
                      phoneNumber: _phoneNumber,
                      onChanged: (phone) => _phoneNumber = phone,
                    ),
                    const SizedBox(height: 16),

                    // Address Section
                    _AddressSection(
                      addressController: _addressController,
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
                    ),

                    const SizedBox(height: 32),

                    // Availability Link
                    _AvailabilityButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                const ManageAvailabilityScreen(),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 32),

                    // Save Button
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

                    // Delete Account
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
}

// ============================================================================
// EXTRACTED WIDGETS
// ============================================================================

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }
}

class _BusinessNameField extends StatelessWidget {
  final TextEditingController controller;

  const _BusinessNameField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: const InputDecoration(
        labelText: 'Nom de l\'entreprise',
        prefixIcon: Icon(Icons.business),
        border: OutlineInputBorder(),
      ),
      validator: (value) =>
          value == null || value.isEmpty ? 'Champ requis' : null,
    );
  }
}

class _DescriptionField extends StatelessWidget {
  final TextEditingController controller;

  const _DescriptionField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: const InputDecoration(
        labelText: 'Description',
        prefixIcon: Icon(Icons.description),
        border: OutlineInputBorder(),
      ),
      maxLines: 3,
    );
  }
}

class _EmailField extends StatelessWidget {
  final TextEditingController controller;

  const _EmailField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: const InputDecoration(
        labelText: 'Email',
        prefixIcon: Icon(Icons.email),
        border: OutlineInputBorder(),
      ),
      keyboardType: TextInputType.emailAddress,
    );
  }
}

class _PhoneField extends StatelessWidget {
  final String? phoneNumber;
  final ValueChanged<String> onChanged;

  const _PhoneField({
    required this.phoneNumber,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return IntlPhoneField(
      key: Key(phoneNumber ?? 'phone_field'),
      decoration: const InputDecoration(
        labelText: 'Numéro de téléphone',
        border: OutlineInputBorder(),
      ),
      initialCountryCode: 'FR',
      initialValue: phoneNumber,
      countries: const [
        Country(
          name: "France",
          nameTranslations: {"fr": "France", "en": "France"},
          flag: "🇫🇷",
          code: "FR",
          dialCode: "33",
          minLength: 9,
          maxLength: 9,
        ),
      ],
      onChanged: (phone) => onChanged(phone.completeNumber),
    );
  }
}

class _AddressSection extends StatelessWidget {
  final TextEditingController addressController;
  final TextEditingController cityController;
  final TextEditingController postalCodeController;
  final AddressService addressService;
  final void Function(AddressResult) onAddressSelected;

  const _AddressSection({
    required this.addressController,
    required this.cityController,
    required this.postalCodeController,
    required this.addressService,
    required this.onAddressSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
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
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: postalCodeController,
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
                controller: cityController,
                decoration: const InputDecoration(
                  labelText: 'Ville',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _AvailabilityButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _AvailabilityButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      icon: const Icon(Icons.schedule),
      label: const Text('Gérer mes horaires d\'ouverture'),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.all(16),
        alignment: Alignment.centerLeft,
        textStyle: const TextStyle(fontSize: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: onPressed,
    );
  }
}
