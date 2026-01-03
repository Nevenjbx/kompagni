import 'package:flutter/material.dart';
import '../services/service_service.dart';

import '../../../shared/models/service.dart';

class AddServiceScreen extends StatefulWidget {
  final Service? service; // If null, we are adding. If not, we are editing.

  const AddServiceScreen({super.key, this.service});

  @override
  State<AddServiceScreen> createState() => _AddServiceScreenState();
}

class _AddServiceScreenState extends State<AddServiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _serviceService = ServiceService();

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
      if (widget.service == null) {
        await _serviceService.createService(
          name: _name,
          description: _description.isEmpty ? null : _description,
          duration: _duration,
          price: _price,
          animalType: _animalType,
        );
      } else {
        await _serviceService.updateService(
          id: widget.service!.id,
          name: _name,
          description: _description.isEmpty ? null : _description,
          duration: _duration,
          price: _price,
          animalType: _animalType,
        );
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text(widget.service == null ? 'Service ajouté !' : 'Service modifié !')),
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
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          TextButton(
             onPressed: () => Navigator.pop(context, true), 
             style: TextButton.styleFrom(foregroundColor: Colors.red),
             child: const Text('Supprimer')
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        await _serviceService.deleteService(widget.service!.id);
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
                decoration: const InputDecoration(labelText: 'Nom du service'),
                validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
                onSaved: (v) => _name = v!,
              ),
              TextFormField(
                initialValue: _description,
                decoration: const InputDecoration(labelText: 'Description'),
                onSaved: (v) => _description = v ?? '',
              ),
              TextFormField(
                initialValue: _duration.toString(),
                decoration: const InputDecoration(labelText: 'Durée (minutes)'),
                keyboardType: TextInputType.number,
                validator: (v) => v == null || int.tryParse(v) == null ? 'Nombre entier requis' : null,
                onSaved: (v) => _duration = int.parse(v!),
              ),
              TextFormField(
                initialValue: _price.toString(),
                decoration: const InputDecoration(labelText: 'Prix (€)'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) => v == null || double.tryParse(v) == null ? 'Montant requis' : null,
                onSaved: (v) => _price = double.parse(v!),
              ),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Type d\'animal'),
                value: _animalType,
                items: const [
                  DropdownMenuItem(value: 'DOG', child: Text('Chien')),
                  DropdownMenuItem(value: 'CAT', child: Text('Chat')),
                ],
                onChanged: (v) => setState(() => _animalType = v!),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
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
