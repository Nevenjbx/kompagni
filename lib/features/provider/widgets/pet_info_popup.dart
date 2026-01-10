import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/pet.dart';
import '../../../shared/repositories/impl/pet_repository_impl.dart';

/// Quick popup displaying pet information with editable provider notes
class PetInfoPopup extends ConsumerStatefulWidget {
  final Pet pet;

  const PetInfoPopup({
    super.key,
    required this.pet,
  });

  /// Show the popup as a dialog
  static Future<void> show(BuildContext context, Pet pet) {
    return showDialog(
      context: context,
      builder: (context) => PetInfoPopup(pet: pet),
    );
  }

  @override
  ConsumerState<PetInfoPopup> createState() => _PetInfoPopupState();
}

class _PetInfoPopupState extends ConsumerState<PetInfoPopup> {
  final TextEditingController _noteController = TextEditingController();
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _fetchNote();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _fetchNote() async {
    final repository = ref.read(petRepositoryProvider);
    final note = await repository.getPetNote(widget.pet.id);
    if (mounted) {
      if (note != null) {
        _noteController.text = note;
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveNote() async {
    if (_isSaving) return;
    
    setState(() {
      _isSaving = true;
    });

    try {
      final repository = ref.read(petRepositoryProvider);
      await repository.updatePetNote(widget.pet.id, _noteController.text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Note sauvegardée'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de la sauvegarde'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          CircleAvatar(
            backgroundColor: _getPetColor(widget.pet.type),
            child: Icon(_getPetIcon(widget.pet.type), color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.pet.name,
                  style: const TextStyle(fontSize: 18),
                ),
                Text(
                  widget.pet.breed,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Type
            _InfoRow(
              icon: _getPetIcon(widget.pet.type),
              label: 'Type',
              value: _getPetTypeName(widget.pet.type),
            ),
        
            // Size
            _InfoRow(
              icon: Icons.straighten,
              label: 'Taille',
              value: _getPetSizeName(widget.pet.size),
            ),
        
            // Character
            _InfoRow(
              icon: Icons.emoji_emotions,
              label: 'Caractère',
              value: _getPetCharacterName(widget.pet.character),
            ),
        
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
        
            // Provider Note Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.note, size: 16, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text(
                            'Note privée',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                      if (_isSaving)
                        const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_isLoading)
                    const Center(child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(),
                    ))
                  else
                    TextField(
                      controller: _noteController,
                      maxLines: 4,
                      minLines: 2,
                      decoration: InputDecoration(
                        hintText: 'Ajouter une note sur cet animal...',
                        isDense: true,
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: BorderSide(color: Colors.grey.shade600),
                        ),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.save),
                          onPressed: _saveNote,
                          tooltip: 'Sauvegarder',
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Fermer'),
        ),
      ],
    );
  }

  IconData _getPetIcon(AnimalType type) {
    switch (type) {
      case AnimalType.dog:
        return Icons.pets;
      case AnimalType.cat:
        return Icons.pets;
      case AnimalType.other:
        return Icons.cruelty_free;
    }
  }

  Color _getPetColor(AnimalType type) {
    switch (type) {
      case AnimalType.dog:
        return Colors.brown;
      case AnimalType.cat:
        return Colors.orange;
      case AnimalType.other:
        return Colors.green;
    }
  }

  String _getPetTypeName(AnimalType type) {
    switch (type) {
      case AnimalType.dog:
        return 'Chien';
      case AnimalType.cat:
        return 'Chat';
      case AnimalType.other:
        return 'Autre';
    }
  }

  String _getPetSizeName(PetSize size) {
    switch (size) {
      case PetSize.small:
        return 'Petit';
      case PetSize.medium:
        return 'Moyen';
      case PetSize.large:
        return 'Grand';
      case PetSize.giant:
        return 'Géant';
    }
  }

  String _getPetCharacterName(PetCharacter character) {
    switch (character) {
      case PetCharacter.happy:
        return 'Joyeux';
      case PetCharacter.angry:
        return 'Agressif';
      case PetCharacter.calm:
        return 'Calme';
      case PetCharacter.scared:
        return 'Peureux';
      case PetCharacter.energetic:
        return 'Énergique';
    }
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
