import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:quiz_flashcard/models/card_model.dart';
import 'package:quiz_flashcard/models/deck_model.dart';

class CsvImportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<CardModel> parseCards(String csvContent) {
    final normalized =
        csvContent.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    final rows =
        const CsvToListConverter().convert(normalized, eol: '\n');

    if (rows.isEmpty) throw Exception('File CSV kosong');

    final header =
        rows[0].map((e) => e.toString().toLowerCase().trim()).toList();

    final qIdx = header.indexOf('pertanyaan');
    final aIdx = header.indexOf('jawaban');

    if (qIdx == -1) throw Exception('Kolom "pertanyaan" tidak ditemukan');
    if (aIdx == -1) throw Exception('Kolom "jawaban" tidak ditemukan');

    final clueIdxs = [
      header.indexOf('clue1'),
      header.indexOf('clue2'),
      header.indexOf('clue3'),
      header.indexOf('clue4'),
    ];
    final expIdx = header.indexOf('penjelasan');

    final cards = <CardModel>[];
    for (int i = 1; i < rows.length; i++) {
      final row = rows[i];
      final question = _cell(row, qIdx);
      final answer = _cell(row, aIdx);
      if (question.isEmpty || answer.isEmpty) continue;

      final clues = clueIdxs
          .where((idx) => idx != -1)
          .map((idx) => _cell(row, idx))
          .where((c) => c.isNotEmpty)
          .toList();

      String explanation =
          expIdx != -1 ? _cell(row, expIdx) : '';
      if (explanation.isEmpty) {
        explanation = 'Jawaban yang benar adalah: $answer';
      }

      cards.add(CardModel(
        question: question,
        answerText: answer,
        clues: clues,
        explanation: explanation,
        createdAt: Timestamp.now(),
      ));
    }

    if (cards.isEmpty) throw Exception('Tidak ada kartu valid di CSV');
    return cards;
  }

  String _cell(List<dynamic> row, int idx) {
    if (idx < 0 || idx >= row.length) return '';
    return row[idx].toString().trim();
  }

  Future<DeckModel> importDeck({
    required String userId,
    required String ownerName,
    required String title,
    required String description,
    required String category,
    required bool isPublic,
    required List<CardModel> cards,
  }) async {
    final now = Timestamp.now();
    final deckRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('decks')
        .doc();

    final deck = DeckModel(
      id: deckRef.id,
      title: title,
      description: description,
      category: category,
      isPublic: isPublic,
      createdAt: now,
      updatedAt: now,
      cardCount: cards.length,
      ownerId: userId,
      ownerName: ownerName,
    );

    WriteBatch batch = _firestore.batch();
    batch.set(deckRef, deck.toMap());
    int batchCount = 1;

    for (final card in cards) {
      if (batchCount >= 499) {
        await batch.commit();
        batch = _firestore.batch();
        batchCount = 0;
      }
      final cardRef = deckRef.collection('cards').doc();
      batch.set(
        cardRef,
        card.copyWith(id: cardRef.id, createdAt: now).toMap(),
      );
      batchCount++;
    }

    await batch.commit();
    return deck;
  }
}
