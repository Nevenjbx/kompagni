import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/countries.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../shared/repositories/impl/user_repository_impl.dart';
import '../../../core/errors/app_exception.dart';
import 'my_pets_screen.dart';

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

                      // Section: Informations personnelles
                      _SectionTitle(title: 'Informations personnelles'),
                      const SizedBox(height: 16),

                      // Prénom
                      TextFormField(
                        controller: _firstNameController,
                        decoration: const InputDecoration(
                          labelText: 'Prénom',
                          prefixIcon: Icon(Icons.person_outline),
                          border: OutlineInputBorder(),
                        ),
                        textCapitalization: TextCapitalization.words,
                        validator: (value) => value == null || value.isEmpty
                            ? 'Le prénom est requis'
                            : null,
                        onChanged: (_) => _onFieldChanged(),
                      ),
                      const SizedBox(height: 16),

                      // Nom
                      TextFormField(
                        controller: _lastNameController,
                        decoration: const InputDecoration(
                          labelText: 'Nom',
                          prefixIcon: Icon(Icons.person_outline),
                          border: OutlineInputBorder(),
                        ),
                        textCapitalization: TextCapitalization.words,
                        validator: (value) => value == null || value.isEmpty
                            ? 'Le nom est requis'
                            : null,
                        onChanged: (_) => _onFieldChanged(),
                      ),
                      const SizedBox(height: 24),

                      // Section: Coordonnées
                      _SectionTitle(title: 'Coordonnées'),
                      const SizedBox(height: 16),

                      // Email
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email_outlined),
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'L\'email est requis';
                          }
                          if (!value.contains('@')) {
                            return 'Veuillez entrer un email valide';
                          }
                          return null;
                        },
                        onChanged: (_) => _onFieldChanged(),
                      ),
                      const SizedBox(height: 16),

                      // Téléphone
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

                      const SizedBox(height: 24),

                      // Section: Mes Animaux
                      _SectionTitle(title: 'Mes Animaux'),
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

                      // Save Button
                      ElevatedButton.icon(
                        onPressed: _hasChanges && !_isSaving ? _saveProfile : null,
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
                          textStyle: const TextStyle(fontSize: 16),
                        ),
                      ),

                      const SizedBox(height: 32),

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
                          icon:
                              const Icon(Icons.delete_forever, color: Colors.red),
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

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
