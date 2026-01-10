import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/countries.dart';
import '../../../core/errors/app_exception.dart';
import '../../../shared/services/address_service.dart';
import '../../../shared/models/provider.dart' as models;
import '../../../shared/repositories/user_repository.dart';
import '../../../shared/repositories/impl/user_repository_impl.dart';
import '../../../shared/repositories/provider_repository.dart';
import '../../../shared/repositories/impl/provider_repository_impl.dart';
import '../../../shared/providers/provider_profile_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../widgets/provider_section_title.dart';
import '../widgets/tags_editor.dart';
import '../widgets/address_form_section.dart';
import 'manage_availability_screen.dart';

/// Provider account editing screen.
/// 
/// Refactored to match client_profile_screen pattern with:
/// - Modular widgets for each section
/// - Supabase Auth sync via backend API
/// - Tags management
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
  bool _isSaving = false;
  bool _hasChanges = false;

  // User info controllers
  late TextEditingController _emailController;
  String? _phoneNumber;

  // Provider info controllers
  late TextEditingController _businessNameController;
  late TextEditingController _descriptionController;
  late TextEditingController _addressController;
  late TextEditingController _cityController;
  late TextEditingController _postalCodeController;

  // Location
  double? _latitude;
  double? _longitude;

  // Tags
  late List<String> _selectedTags;

  @override
  void initState() {
    super.initState();
    // User info
    _emailController = TextEditingController();

    // Provider info
    _businessNameController = TextEditingController(text: widget.provider.businessName);
    _descriptionController = TextEditingController(text: widget.provider.description);
    _addressController = TextEditingController(text: widget.provider.address);
    _cityController = TextEditingController(text: widget.provider.city);
    _postalCodeController = TextEditingController(text: widget.provider.postalCode);

    _latitude = widget.provider.latitude;
    _longitude = widget.provider.longitude;
    _selectedTags = List<String>.from(widget.provider.tags);

    _loadUserData();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _businessNameController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _postalCodeController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);

    try {
      final userRepository = ref.read(userRepositoryProvider);
      final userData = await userRepository.getCurrentUser();

      if (userData != null && mounted) {
        setState(() {
          _emailController.text = userData['email'] ?? '';
          _phoneNumber = userData['phoneNumber'];
        });
      }
    } catch (e) {
      // Ignore silently - user data will just be empty
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onFieldChanged() {
    if (!_hasChanges) {
      setState(() => _hasChanges = true);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      // 1. Update provider profile (includes tags)
      final providerUpdates = {
        'businessName': _businessNameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'address': _addressController.text.trim(),
        'city': _cityController.text.trim(),
        'postalCode': _postalCodeController.text.trim(),
        'latitude': _latitude,
        'longitude': _longitude,
        'tags': _selectedTags,
      };

      final providerRepository = ref.read(providerRepositoryProvider);
      await providerRepository.updateProfile(providerUpdates);

      // 2. Update user info (syncs with Supabase Auth automatically via backend)
      final userUpdates = <String, dynamic>{};

      final email = _emailController.text.trim();

      if (email.isNotEmpty) {
        userUpdates['email'] = email;
      }
      if (_phoneNumber != null && _phoneNumber!.isNotEmpty) {
        userUpdates['phoneNumber'] = _phoneNumber;
      }

      if (userUpdates.isNotEmpty) {
        final userRepository = ref.read(userRepositoryProvider);
        await userRepository.updateUser(userUpdates);
      }

      // Refresh provider profile
      ref.invalidate(providerProfileProvider);

      if (mounted) {
        setState(() => _hasChanges = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil mis à jour avec succès !'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      String errorMessage = 'Erreur lors de la sauvegarde';
      if (e is AppException) {
        errorMessage = e.message;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer mon compte'),
        content: const Text(
          'Êtes-vous sûr de vouloir supprimer votre compte ?\n\n'
          'Cette action est irréversible et supprimera toutes vos données, '
          'y compris vos rendez-vous et services.',
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

    setState(() => _isSaving = true);

    try {
      // Delete account (syncs with Supabase Auth via backend)
      final userRepository = ref.read(userRepositoryProvider);
      await userRepository.deleteAccount();

      // Sign out
      final authService = ref.read(authServiceProvider);
      await authService.signOut();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la suppression: $e')),
        );
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modifier mon compte'),
        actions: [
          if (_hasChanges)
            TextButton(
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(
                      'Enregistrer',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadUserData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Avatar
                      const Center(
                        child: CircleAvatar(
                          radius: 50,
                          child: Icon(Icons.business, size: 50),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Business Info Section
                      const ProviderSectionTitle(title: 'Informations Entreprise'),
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
                        onChanged: (_) => _onFieldChanged(),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          prefixIcon: Icon(Icons.description),
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                        ),
                        maxLines: 3,
                        onChanged: (_) => _onFieldChanged(),
                      ),
                      const SizedBox(height: 24),

                      // Contact Section
                      const ProviderSectionTitle(title: 'Coordonnées'),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email),
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        onChanged: (_) => _onFieldChanged(),
                      ),
                      const SizedBox(height: 16),
                      IntlPhoneField(
                        key: Key(_phoneNumber ?? 'phone_field'),
                        decoration: const InputDecoration(
                          labelText: 'Numéro de téléphone',
                          border: OutlineInputBorder(),
                        ),
                        initialCountryCode: 'FR',
                        initialValue: _phoneNumber,
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
                        onChanged: (phone) {
                          _phoneNumber = phone.completeNumber;
                          _onFieldChanged();
                        },
                      ),
                      const SizedBox(height: 16),

                      // Address Section
                      AddressFormSection(
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
                          _onFieldChanged();
                        },
                      ),
                      const SizedBox(height: 24),

                      // Tags Section
                      TagsEditor(
                        availableTags: TagsEditor.defaultTags,
                        selectedTags: _selectedTags,
                        onTagsChanged: (tags) {
                          setState(() => _selectedTags = tags);
                          _onFieldChanged();
                        },
                      ),
                      const SizedBox(height: 32),

                      // Manage Availability
                      OutlinedButton.icon(
                        icon: const Icon(Icons.schedule),
                        label: const Text('Gérer mes horaires d\'ouverture'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                          alignment: Alignment.centerLeft,
                          textStyle: const TextStyle(fontSize: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const ManageAvailabilityScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 32),

                      // Save Button
                      ElevatedButton.icon(
                        onPressed: _hasChanges && !_isSaving ? _save : null,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.save),
                        label: const Text('Enregistrer les modifications'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          textStyle: const TextStyle(fontSize: 18),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Logout Button
                      OutlinedButton.icon(
                        onPressed: () async {
                          final authService = ref.read(authServiceProvider);
                          await authService.signOut();
                        },
                        icon: const Icon(Icons.logout),
                        label: const Text('Me déconnecter'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.orange,
                          side: const BorderSide(color: Colors.orange),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
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
            ),
    );
  }
}
