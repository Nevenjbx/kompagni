import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../shared/repositories/user_repository.dart';
import '../../../shared/repositories/impl/user_repository_impl.dart';
import '../../../core/errors/app_exception.dart';
import '../widgets/profile_section_title.dart';
import '../widgets/personal_info_form_section.dart';
import '../widgets/contact_info_form_section.dart';
import '../widgets/profile_action_buttons.dart';
import 'my_pets_screen.dart';

/// Client profile screen for viewing and editing user account information.
/// 
/// This screen has been refactored to use modular widgets:
/// - [PersonalInfoFormSection] for name fields
/// - [ContactInfoFormSection] for email and phone
/// - [ProfileActionButtons] for save, logout, delete actions
class ClientProfileScreen extends ConsumerStatefulWidget {
  const ClientProfileScreen({super.key});

  @override
  ConsumerState<ClientProfileScreen> createState() =>
      _ClientProfileScreenState();
}

class _ClientProfileScreenState extends ConsumerState<ClientProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  bool _isSaving = false;
  bool _hasChanges = false;

  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  String? _phoneNumber;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _emailController = TextEditingController();

    _loadUserData();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);

    try {
      final userRepository = ref.read(userRepositoryProvider);
      final userData = await userRepository.getCurrentUser();

      if (userData != null && mounted) {
        setState(() {
          _firstNameController.text = userData['firstName'] ?? '';
          _lastNameController.text = userData['lastName'] ?? '';
          _emailController.text = userData['email'] ?? '';
          _phoneNumber = userData['phoneNumber'];
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur de chargement: $e')),
        );
      }
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

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final userRepository = ref.read(userRepositoryProvider);

      final updates = <String, dynamic>{};

      final firstName = _firstNameController.text.trim();
      final lastName = _lastNameController.text.trim();
      final email = _emailController.text.trim();

      if (firstName.isNotEmpty) {
        updates['firstName'] = firstName;
      }
      if (lastName.isNotEmpty) {
        updates['lastName'] = lastName;
      }
      if (email.isNotEmpty) {
        updates['email'] = email;
      }
      if (_phoneNumber != null && _phoneNumber!.isNotEmpty) {
        updates['phoneNumber'] = _phoneNumber;
      }

      if (updates.isNotEmpty) {
        await userRepository.updateUser(updates);
      }

      if (mounted) {
        setState(() => _hasChanges = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil mis à jour avec succès !'),
            backgroundColor: Colors.green,
          ),
        );
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

    setState(() => _isSaving = true);

    try {
      final userRepository = ref.read(userRepositoryProvider);
      await userRepository.deleteAccount();

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
        title: const Text('Mon Compte'),
        actions: [
          if (_hasChanges)
            TextButton(
              onPressed: _isSaving ? null : _saveProfile,
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
                          child: Icon(Icons.person, size: 50),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Personal Info Section
                      PersonalInfoFormSection(
                        firstNameController: _firstNameController,
                        lastNameController: _lastNameController,
                        onFieldChanged: _onFieldChanged,
                      ),
                      const SizedBox(height: 24),

                      // Contact Info Section
                      ContactInfoFormSection(
                        emailController: _emailController,
                        phoneNumber: _phoneNumber,
                        onPhoneChanged: (phone) => _phoneNumber = phone,
                        onFieldChanged: _onFieldChanged,
                      ),
                      const SizedBox(height: 24),

                      // My Pets Section
                      const ProfileSectionTitle(title: 'Mes Animaux'),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const MyPetsScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.pets),
                        label: const Text('Gérer mes animaux'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          textStyle: const TextStyle(fontSize: 16),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Action Buttons
                      ProfileActionButtons(
                        hasChanges: _hasChanges,
                        isSaving: _isSaving,
                        onSave: _saveProfile,
                        onDelete: _deleteAccount,
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
