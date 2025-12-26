import 'package:flutter/material.dart';
import '../services/service_service.dart';

class AddServiceScreen extends StatefulWidget {
  const AddServiceScreen({super.key});

  @override
  State<AddServiceScreen> createState() => _AddServiceScreenState();
}

class _AddServiceScreenState extends State<AddServiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _serviceService = ServiceService();

  String _name = '';
  String _description = '';
  int _duration = 30;
  double _price = 0.0;
  String _animalType = 'DOG';
  bool _isLoading = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _isLoading = true);

    try {
      await _serviceService.createService(
        name: _name,
        description: _description.isEmpty ? null : _description,
        duration: _duration,
        price: _price,
        animalType: _animalType,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Service ajouté avec succès !')),
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
      appBar: AppBar(title: const Text('Ajouter un service')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Nom du service'),
                validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
                onSaved: (v) => _name = v!,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Description'),
                onSaved: (v) => _description = v ?? '',
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Durée (minutes)'),
                keyboardType: TextInputType.number,
                initialValue: '30',
                validator: (v) => v == null || int.tryParse(v) == null ? 'Nombre entier requis' : null,
                onSaved: (v) => _duration = int.parse(v!),
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Prix (€)'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                initialValue: '0',
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
                    : const Text('Ajouter'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
