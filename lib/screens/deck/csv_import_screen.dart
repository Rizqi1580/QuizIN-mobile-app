import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quiz_flashcard/models/card_model.dart';
import 'package:quiz_flashcard/screens/deck/deck_detail_screen.dart';
import 'package:quiz_flashcard/services/csv_import_service.dart';

class CsvImportScreen extends StatefulWidget {
  const CsvImportScreen({super.key});

  @override
  State<CsvImportScreen> createState() => _CsvImportScreenState();
}

class _CsvImportScreenState extends State<CsvImportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final CsvImportService _importService = CsvImportService();

  final List<String> _categories = [
    'Matematika',
    'Sains',
    'Bahasa',
    'Sejarah',
    'Pemrograman',
    'Lainnya',
  ];

  String _category = 'Lainnya';
  bool _isPublic = false;
  bool _isImporting = false;

  String? _csvFileName;
  List<CardModel>? _parsedCards;
  String? _parseError;

  static const String _templateContent =
      'pertanyaan,jawaban,clue1,clue2,clue3,clue4,penjelasan\n'
      'Ibu kota Indonesia?,Jakarta,Pulau Jawa,Kota terbesar,,,Jakarta adalah ibu kota Indonesia.\n'
      'Siapa presiden pertama RI?,Soekarno,Proklamator,Bung Karno,,,'
      '"Soekarno, juga dikenal sebagai Bung Karno, adalah presiden pertama RI."';

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      withData: true,
    );
    if (result == null) return;

    final file = result.files.first;
    final name = file.name.toLowerCase();
    if (!name.endsWith('.csv')) {
      setState(() {
        _parsedCards = null;
        _parseError = 'File harus berekstensi .csv';
        _csvFileName = file.name;
      });
      return;
    }

    setState(() {
      _parsedCards = null;
      _parseError = null;
      _csvFileName = file.name;
    });

    try {
      String content;
      if (file.bytes != null) {
        content = String.fromCharCodes(file.bytes!);
      } else if (file.path != null) {
        content = await File(file.path!).readAsString();
      } else {
        throw Exception('Tidak dapat membaca file');
      }

      final cards = _importService.parseCards(content);
      setState(() => _parsedCards = cards);
    } catch (e) {
      setState(() {
        _parseError = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _doImport() async {
    if (!_formKey.currentState!.validate() || _parsedCards == null) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isImporting = true);

    try {
      final deck = await _importService.importDeck(
        userId: user.uid,
        ownerName: user.displayName ?? user.email ?? 'Unknown',
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        category: _category,
        isPublic: _isPublic,
        cards: _parsedCards!,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_parsedCards!.length} kartu berhasil diimpor!'),
        ),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => DeckDetailScreen(deck: deck)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengimpor: $e')),
      );
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canImport = _parsedCards != null && !_isImporting;

    return Scaffold(
      appBar: AppBar(title: const Text('Import dari CSV')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGuideSection(context),
            const SizedBox(height: 16),
            _buildDeckInfoSection(context),
            const SizedBox(height: 16),
            _buildFileSection(context),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: canImport ? _doImport : null,
                icon: _isImporting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.cloud_upload_outlined),
                label: Text(_isImporting ? 'Mengimpor...' : 'Import Deck'),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildGuideSection(BuildContext context) {
    return Card(
      child: ExpansionTile(
        leading: const Icon(Icons.help_outline),
        title: const Text('Panduan & Template CSV'),
        initiallyExpanded: true,
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          const _GuideStep(number: '1', text: 'Salin template CSV di bawah'),
          const _GuideStep(
              number: '2',
              text:
                  'Buka di aplikasi spreadsheet (Excel / Google Sheets)'),
          const _GuideStep(
              number: '3', text: 'Isi baris data sesuai kolom:'),
          const Padding(
            padding: EdgeInsets.only(left: 28, bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ColumnDesc(
                    col: 'pertanyaan',
                    desc: 'Pertanyaan flashcard',
                    required: true),
                _ColumnDesc(
                    col: 'jawaban',
                    desc: 'Jawaban yang benar',
                    required: true),
                _ColumnDesc(
                    col: 'clue1 – clue4',
                    desc: 'Petunjuk opsional, boleh dikosongkan'),
                _ColumnDesc(
                    col: 'penjelasan',
                    desc: 'Penjelasan jawaban, diisi otomatis jika kosong'),
              ],
            ),
          ),
          const _GuideStep(number: '4', text: 'Simpan file sebagai .csv'),
          const _GuideStep(
              number: '5',
              text:
                  'Isi informasi deck di bawah, pilih file, lalu tekan Import'),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              _templateContent,
              style: TextStyle(fontFamily: 'monospace', fontSize: 11),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () {
              Clipboard.setData(
                  const ClipboardData(text: _templateContent));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Template disalin ke clipboard')),
              );
            },
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('Salin Template'),
          ),
        ],
      ),
    );
  }

  Widget _buildDeckInfoSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Informasi Deck',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _titleController,
                decoration:
                    const InputDecoration(labelText: 'Judul Deck'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty)
                        ? 'Judul wajib diisi'
                        : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(
                    labelText: 'Deskripsi (opsional)'),
                maxLines: 2,
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: _category,
                items: _categories
                    .map((c) =>
                        DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) =>
                    setState(() => _category = v ?? 'Lainnya'),
                decoration:
                    const InputDecoration(labelText: 'Kategori'),
              ),
              const SizedBox(height: 4),
              SwitchListTile(
                value: _isPublic,
                title: const Text('Deck Publik'),
                contentPadding: EdgeInsets.zero,
                onChanged: (v) => setState(() => _isPublic = v),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFileSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'File CSV',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _pickFile,
              icon: const Icon(Icons.upload_file),
              label: const Text('Pilih File (.csv)'),
            ),
            if (_csvFileName != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.description_outlined,
                      size: 16, color: Colors.grey),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _csvFileName!,
                      style: const TextStyle(fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            if (_parseError != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Error: $_parseError',
                  style: const TextStyle(color: Colors.red, fontSize: 13),
                ),
              ),
            if (_parsedCards != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.check_circle,
                      size: 16, color: Colors.green[600]),
                  const SizedBox(width: 6),
                  Text(
                    '${_parsedCards!.length} kartu ditemukan',
                    style: TextStyle(
                      color: Colors.green[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _CardPreviewList(cards: _parsedCards!),
            ],
          ],
        ),
      ),
    );
  }
}

class _GuideStep extends StatelessWidget {
  final String number;
  final String text;

  const _GuideStep({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 10,
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: Text(
              number,
              style: const TextStyle(fontSize: 10, color: Colors.white),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

class _ColumnDesc extends StatelessWidget {
  final String col;
  final String desc;
  final bool required;

  const _ColumnDesc({
    required this.col,
    required this.desc,
    this.required = false,
  });

  @override
  Widget build(BuildContext context) {
    final baseStyle = DefaultTextStyle.of(context)
        .style
        .copyWith(fontSize: 12);
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: RichText(
        text: TextSpan(
          style: baseStyle,
          children: [
            TextSpan(
              text: col,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontWeight: FontWeight.w600,
              ),
            ),
            TextSpan(text: ': $desc'),
            if (required)
              const TextSpan(
                text: ' *',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CardPreviewList extends StatefulWidget {
  final List<CardModel> cards;

  const _CardPreviewList({required this.cards});

  @override
  State<_CardPreviewList> createState() => _CardPreviewListState();
}

class _CardPreviewListState extends State<_CardPreviewList> {
  static const int _previewCount = 3;
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final showCount = _expanded
        ? widget.cards.length
        : _previewCount.clamp(0, widget.cards.length);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pratinjau:',
          style: Theme.of(context).textTheme.labelMedium,
        ),
        const SizedBox(height: 6),
        for (int i = 0; i < showCount; i++)
          _PreviewCard(index: i + 1, card: widget.cards[i]),
        if (widget.cards.length > _previewCount)
          TextButton(
            onPressed: () => setState(() => _expanded = !_expanded),
            child: Text(
              _expanded
                  ? 'Tampilkan lebih sedikit'
                  : '+ ${widget.cards.length - _previewCount} kartu lainnya',
            ),
          ),
      ],
    );
  }
}

class _PreviewCard extends StatelessWidget {
  final int index;
  final CardModel card;

  const _PreviewCard({required this.index, required this.card});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(
            color: Colors.grey.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$index. ${card.question}',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '→ ${card.answerText}',
            style: const TextStyle(fontSize: 12),
          ),
          if (card.clues.isNotEmpty)
            Text(
              'Clue: ${card.clues.join(', ')}',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
            ),
        ],
      ),
    );
  }
}
