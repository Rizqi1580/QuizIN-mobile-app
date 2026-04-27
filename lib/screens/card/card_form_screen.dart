import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:quiz_flashcard/models/card_model.dart';
import 'package:quiz_flashcard/services/card_service.dart';
import 'package:quiz_flashcard/services/storage_service.dart';

class CardFormScreen extends StatefulWidget {
  final String userId;
  final String deckId;
  final CardModel? card;

  const CardFormScreen({
    super.key,
    required this.userId,
    required this.deckId,
    this.card,
  });

  @override
  State<CardFormScreen> createState() => _CardFormScreenState();
}

class _CardFormScreenState extends State<CardFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _questionController = TextEditingController();
  final _answerController = TextEditingController();
  final _explanationController = TextEditingController();
  final List<TextEditingController> _clueControllers = [];

  final CardService _cardService = CardService();
  final StorageService _storageService = StorageService();
  final ImagePicker _picker = ImagePicker();

  bool _isLoading = false;
  bool _isUploadingImage = false;

  File? _selectedImage;
  String? _existingImagePath;
  bool _removeImage = false;

  bool get _isEdit => widget.card != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      final card = widget.card!;
      _questionController.text = card.question;
      _answerController.text = card.answerText;
      final existingClues = card.clues;
      final initialCount = existingClues.isEmpty ? 1 : existingClues.length;
      for (int i = 0; i < initialCount; i++) {
        _clueControllers.add(TextEditingController(
          text: i < existingClues.length ? existingClues[i] : '',
        ));
      }
      _existingImagePath = card.imageUrl;
      _explanationController.text = card.explanation;
    } else {
      _clueControllers.add(TextEditingController());
    }
  }

  @override
  void dispose() {
    _questionController.dispose();
    _answerController.dispose();
    _explanationController.dispose();
    for (final c in _clueControllers) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImage() async {
    await showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Pilih dari Galeri'),
              onTap: () async {
                Navigator.pop(ctx);
                final XFile? result = await _picker.pickImage(
                  source: ImageSource.gallery,
                  imageQuality: 80,
                );
                if (result != null && mounted) {
                  setState(() {
                    _selectedImage = File(result.path);
                    _removeImage = false;
                  });
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Ambil Foto'),
              onTap: () async {
                Navigator.pop(ctx);
                final XFile? result = await _picker.pickImage(
                  source: ImageSource.camera,
                  imageQuality: 80,
                );
                if (result != null && mounted) {
                  setState(() {
                    _selectedImage = File(result.path);
                    _removeImage = false;
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _removeImagePressed() {
    setState(() {
      _selectedImage = null;
      _existingImagePath = null;
      _removeImage = true;
    });
  }

  Widget _buildImageSection() {
    if (_selectedImage != null) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              _selectedImage!,
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: IconButton(
              icon: const Icon(Icons.cancel, color: Colors.red, size: 28),
              onPressed: _removeImagePressed,
            ),
          ),
        ],
      );
    }

    if (_existingImagePath != null &&
        !_removeImage &&
        File(_existingImagePath!).existsSync()) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              File(_existingImagePath!),
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: IconButton(
              icon: const Icon(Icons.cancel, color: Colors.red, size: 28),
              onPressed: _removeImagePressed,
            ),
          ),
        ],
      );
    }

    return OutlinedButton.icon(
      onPressed: _pickImage,
      icon: const Icon(Icons.add_photo_alternate_outlined),
      label: const Text('Tambah Gambar (Opsional)'),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 48),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.uid != widget.userId) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Anda tidak memiliki akses')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final clues = _clueControllers
      .map((c) => c.text.trim())
      .where((clue) => clue.isNotEmpty)
      .toList();
    final explanationText = _explanationController.text.trim();

    try {
      final String cardId = _isEdit
          ? widget.card!.id
          : FirebaseFirestore.instance
              .collection('users')
              .doc(widget.userId)
              .collection('decks')
              .doc(widget.deckId)
              .collection('cards')
              .doc()
              .id;

      String? imagePath = _existingImagePath;

      if (_removeImage && widget.card?.imageUrl != null) {
        await _storageService.deleteCardImage(
          userId: widget.userId,
          deckId: widget.deckId,
          cardId: cardId,
        );
        imagePath = null;
      }

      if (_selectedImage != null) {
        setState(() => _isUploadingImage = true);
        imagePath = await _storageService.uploadCardImage(
          userId: widget.userId,
          deckId: widget.deckId,
          cardId: cardId,
          imageFile: _selectedImage!,
        );
        setState(() => _isUploadingImage = false);
      }

      final newCard = CardModel(
        id: cardId,
        question: _questionController.text.trim(),
        answerText: _answerController.text.trim(),
        clues: clues,
        createdAt: _isEdit ? widget.card!.createdAt : Timestamp.now(),
        imageUrl: imagePath,
        explanation: explanationText,
      );

      if (_isEdit) {
        await _cardService.updateCard(
          widget.userId,
          widget.deckId,
          cardId,
          newCard.toMap(),
        );
      } else {
        await _cardService.addCard(
          widget.userId,
          widget.deckId,
          newCard,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEdit
              ? 'Kartu berhasil diperbarui'
              : 'Kartu berhasil ditambahkan'),
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUploadingImage = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan kartu: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit Kartu' : 'Tambah Kartu')),
      body: Stack(
        children: [
          Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Gambar soal
                _buildImageSection(),
                const SizedBox(height: 16),

                // Pertanyaan
                TextFormField(
                  controller: _questionController,
                  decoration:
                      const InputDecoration(labelText: 'Pertanyaan'),
                  maxLines: 3,
                  minLines: 1,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Pertanyaan wajib diisi';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Jawaban
                TextFormField(
                  controller: _answerController,
                  decoration: const InputDecoration(labelText: 'Jawaban'),
                  maxLines: 2,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Jawaban wajib diisi';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Clue
                const Text('Clue (maksimal 4, opsional):'),
                const SizedBox(height: 8),
                for (int i = 0; i < _clueControllers.length; i++) ...[
                  TextFormField(
                    controller: _clueControllers[i],
                    decoration: InputDecoration(
                      labelText: 'Clue ${i + 1}',
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                if (_clueControllers.length < 4)
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _clueControllers.add(TextEditingController());
                      });
                    },
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Tambah Clue'),
                  ),

                const Divider(),
                const SizedBox(height: 8),

                // Penjelasan jawaban
                TextFormField(
                  controller: _explanationController,
                  decoration: InputDecoration(
                    labelText: 'Penjelasan Jawaban',
                    hintText: 'Opsional. Jika kosong, sistem isi jawaban benar otomatis.',
                    alignLabelWithHint: true,
                    border: const OutlineInputBorder(),
                    suffixIcon: _isLoading
                        ? const Padding(
                            padding: EdgeInsets.all(8),
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : null,
                  ),
                  maxLines: 4,
                  minLines: 2,
                  enabled: !_isLoading,
                ),
                const SizedBox(height: 16),

                // Tombol simpan
                ElevatedButton(
                  onPressed:
                      (_isLoading || _isUploadingImage) ? null : _submit,
                  child: _isUploadingImage
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2),
                            ),
                            SizedBox(width: 10),
                            Text('Menyimpan gambar...'),
                          ],
                        )
                      : Text(_isEdit ? 'Update Kartu' : 'Simpan Kartu'),
                ),
              ],
            ),
          ),
          if (_isLoading && !_isUploadingImage)
            Container(
              color: Colors.black12,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}