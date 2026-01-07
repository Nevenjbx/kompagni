import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/service.dart';
import '../../../shared/providers/services_provider.dart';
import '../../../shared/providers/provider_profile_provider.dart';

class AddServiceScreen extends ConsumerStatefulWidget {
  final Service? service; // If null, we are adding. If not, we are editing.

  const AddServiceScreen({super.key, this.service});

  @override
  ConsumerState<AddServiceScreen> createState() => _AddServiceScreenState();
}

class _AddServiceScreenState extends ConsumerState<AddServiceScreen> {
  final _formKey = GlobalKey<FormState>();

  late String _name;
  late String _description;
  late int _duration;
  late double _price;
  late String _animalType;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final s = widget.service;
    _name = s?.name ?? '';
    _description = s?.description ?? '';
    _duration = s?.duration ?? 30;
    _price = s?.price ?? 0.0;
    _animalType = s?.animalType ?? 'DOG';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _isLoading = true);

    try {
      final servicesNotifier = ref.read(servicesProvider.notifier);

      if (widget.service == null) {
        await servicesNotifier.createService(
          name: _name,
          description: _description.isEmpty ? null : _description,
          duration: _duration,
          price: _price,
          animalType: _animalType,
        );
      } else {
        await servicesNotifier.updateService(
          id: widget.service!.id,
          name: _name,
          description: _description.isEmpty ? null : _description,
          duration: _duration,
          price: _price,
          animalType: _animalType,
        );
      }

      // Refresh provider profile to get updated services list
      ref.invalidate(providerProfileProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.service == null ? 'Service ajouté !' : 'Service modifié !',
            ),
          ),
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

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer ce service ?'),
        content: const Text('Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        await ref
            .read(servicesProvider.notifier)
            .deleteService(widget.service!.id);

        // Refresh provider profile
        ref.invalidate(providerProfileProvider);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Service supprimé.')),
          );
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: $e')),
          );
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.service != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Modifier le service' : 'Ajouter un service'),
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: _isLoading ? null : _delete,
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                initialValue: _name,
                decoration: const InputDecoration(
                  labelText: 'Nom du service',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
                onSaved: (v) => _name = v!,
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _description,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                onSaved: (v) => _description = v ?? '',
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _duration.toString(),
                decoration: const InputDecoration(
                  labelText: 'Durée (minutes)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (v) =>
                    v == null || int.tryParse(v) == null ? 'Nombre entier requis' : null,
                onSaved: (v) => _duration = int.parse(v!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _price.toString(),
                decoration: const InputDecoration(
                  labelText: 'Prix (€)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) =>
                    v == null || double.tryParse(v) == null ? 'Montant requis' : null,
                onSaved: (v) => _price = double.parse(v!),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Type d\'animal',
                  border: OutlineInputBorder(),
                ),
                value: _animalType,
                items: const [
                  DropdownMenuItem(value: 'DOG', child: Text('Chien')),
                  DropdownMenuItem(value: 'CAT', child: Text('Chat')),
                  DropdownMenuItem(value: 'OTHER', child: Text('Autre')),
                ],
                onChanged: (v) => setState(() => _animalType = v!),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : Text(isEditing ? 'Enregistrer' : 'Ajouter'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
