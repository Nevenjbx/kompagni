import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/pet.dart';
import '../../../shared/providers/pets_provider.dart';

class AddPetScreen extends ConsumerStatefulWidget {
  const AddPetScreen({super.key});

  @override
  ConsumerState<AddPetScreen> createState() => _AddPetScreenState();
}

class _AddPetScreenState extends ConsumerState<AddPetScreen> {
  final _formKey = GlobalKey<FormState>();

  String _name = '';
  AnimalType _type = AnimalType.DOG;
  String _breed = '';
  PetSize _size = PetSize.SMALL;
  PetCharacter _character = PetCharacter.HAPPY;
  bool _isLoading = false;

  static const Map<AnimalType, String> _typeLabels = {
    AnimalType.DOG: 'Chien',
    AnimalType.CAT: 'Chat',
    AnimalType.OTHER: 'Autre',
  };

  static const Map<PetSize, String> _sizeLabels = {
    PetSize.SMALL: 'Petit',
    PetSize.MEDIUM: 'Moyen',
    PetSize.LARGE: 'Grand',
    PetSize.GIANT: 'Géant',
  };

  static const Map<PetCharacter, String> _characterLabels = {
    PetCharacter.HAPPY: 'Joyeux',
    PetCharacter.ANGRY: 'Énervé',
    PetCharacter.CALM: 'Calme',
    PetCharacter.SCARED: 'Peureux',
    PetCharacter.ENERGETIC: 'Énergique',
  };

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _isLoading = true);

    try {
      await ref.read(petsProvider.notifier).addPet(
            name: _name,
            type: _type,
            breed: _breed,
            size: _size,
            character: _character,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Compagnon ajouté avec succès !')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajouter un animal')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Nom',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
                onSaved: (v) => _name = v!,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<AnimalType>(
                decoration: const InputDecoration(
                  labelText: 'Type',
                  border: OutlineInputBorder(),
                ),
                value: _type,
                items: AnimalType.values.map((t) {
                  return DropdownMenuItem(
                    value: t,
                    child: Text(_typeLabels[t] ?? t.toString()),
                  );
                }).toList(),
                onChanged: (v) => setState(() => _type = v!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Race',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
                onSaved: (v) => _breed = v!,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<PetSize>(
                decoration: const InputDecoration(
                  labelText: 'Taille',
                  border: OutlineInputBorder(),
                ),
                value: _size,
                items: PetSize.values.map((s) {
                  return DropdownMenuItem(
                    value: s,
                    child: Text(_sizeLabels[s] ?? s.toString()),
                  );
                }).toList(),
                onChanged: (v) => setState(() => _size = v!),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<PetCharacter>(
                decoration: const InputDecoration(
                  labelText: 'Caractère',
                  border: OutlineInputBorder(),
                ),
                value: _character,
                items: PetCharacter.values.map((c) {
                  return DropdownMenuItem(
                    value: c,
                    child: Text(_characterLabels[c] ?? c.toString()),
                  );
                }).toList(),
                onChanged: (v) => setState(() => _character = v!),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Ajouter'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
