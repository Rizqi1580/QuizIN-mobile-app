import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:quiz_flashcard/models/deck_model.dart';
import 'package:quiz_flashcard/services/deck_service.dart';

class DeckFormScreen extends StatefulWidget {
  final DeckModel? deck;

  const DeckFormScreen({super.key, this.deck});

  @override
  State<DeckFormScreen> createState() => _DeckFormScreenState();
}

class _DeckFormScreenState extends State<DeckFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final DeckService _deckService = DeckService();

  final List<String> _categories = <String>[
    'General',
    'Math',
    'Science',
    'Language',
    'History',
    'Programming',
  ];

  bool _isLoading = false;
  String _category = 'General';
  bool _isPublic = false;

  bool get _isEdit => widget.deck != null;

  @override
  void initState() {
    super.initState();

    if (_isEdit) {
      final deck = widget.deck!;
      _titleController.text = deck.title;
      _descriptionController.text = deck.description;
      _category = deck.category;
      _isPublic = deck.isPublic;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan login terlebih dahulu')),
      );
      return;
    }

    if (_isEdit && widget.deck!.ownerId != user.uid) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Anda bukan pemilik deck ini')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (_isEdit) {
        await _deckService.updateDeck(widget.deck!.id, {
          'title': _titleController.text.trim(),
          'description': _descriptionController.text.trim(),
          'category': _category,
          'isPublic': _isPublic,
        });
      } else {
        final now = Timestamp.now();
        final deck = DeckModel(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          category: _category,
          isPublic: _isPublic,
          createdAt: now,
          updatedAt: now,
          cardCount: 0,
          ownerId: user.uid,
          ownerName: user.displayName ?? user.email ?? 'Unknown',
        );
        await _deckService.createDeck(deck);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEdit ? 'Deck berhasil diperbarui' : 'Deck berhasil dibuat'),
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan deck: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteDeck() async {
    if (!_isEdit) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan login terlebih dahulu')),
      );
      return;
    }

    if (widget.deck!.ownerId != user.uid) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Anda bukan pemilik deck ini')),
      );
      return;
    }

    final bool confirmDelete = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Hapus deck?'),
            content: Text(
              'Deck "${widget.deck!.title}" akan dihapus permanen beserta kartunya.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Batal'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Hapus'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmDelete) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _deckService.deleteDeck(user.uid, widget.deck!.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Deck berhasil dihapus')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menghapus deck: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit Deck' : 'Buat Deck')),
      body: Stack(
        children: [
          Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Judul Deck'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Judul wajib diisi';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Deskripsi'),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _category,
                  items: _categories
                      .map((category) => DropdownMenuItem<String>(
                            value: category,
                            child: Text(category),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _category = value ?? 'General';
                    });
                  },
                  decoration: const InputDecoration(labelText: 'Kategori'),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  value: _isPublic,
                  title: const Text('Deck Publik'),
                  onChanged: (value) {
                    setState(() {
                      _isPublic = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  child: Text(_isEdit ? 'Update Deck' : 'Simpan Deck'),
                ),
                if (_isEdit) ...[
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: _isLoading ? null : _deleteDeck,
                    icon: const Icon(Icons.delete_outline),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                    label: const Text('Hapus Deck'),
                  ),
                ],
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black12,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
