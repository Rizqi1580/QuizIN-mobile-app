import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:quiz_flashcard/models/card_model.dart';

class CardService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _deckRef(String userId, String deckId) {
    return _firestore.collection('users').doc(userId).collection('decks').doc(deckId);
  }

  CollectionReference<Map<String, dynamic>> _cardRef(String userId, String deckId) {
    return _deckRef(userId, deckId).collection('cards');
  }

  /// Add card dengan penjelasan default jika user tidak mengisi
  Future<void> addCard(String userId, String deckId, CardModel card) async {
    String explanation = card.explanation.trim();
    if (explanation.isEmpty) {
      explanation = _buildDefaultExplanation(card.answerText);
    }

    final newCardRef = _cardRef(userId, deckId).doc();
    final batch = _firestore.batch();

    batch.set(
      newCardRef,
      card
          .copyWith(id: newCardRef.id, createdAt: Timestamp.now(), explanation: explanation)
          .toMap(),
    );

    batch.update(_deckRef(userId, deckId), {
      'cardCount': FieldValue.increment(1),
      'updatedAt': Timestamp.now(),
    });

    await batch.commit();
  }

  Stream<List<CardModel>> getCards(String userId, String deckId) {
    return _cardRef(userId, deckId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => CardModel.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  Future<void> updateCard(
    String userId,
    String deckId,
    String cardId,
    Map<String, dynamic> data,
  ) async {
    final String explanation = (data['explanation'] ?? '') as String;
    if (explanation.trim().isEmpty) {
      data['explanation'] = _buildDefaultExplanation(
        (data['answerText'] ?? '') as String,
      );
    }

    await _cardRef(userId, deckId).doc(cardId).update(data);
    await _deckRef(userId, deckId).update({'updatedAt': Timestamp.now()});
  }

  Future<void> deleteCard(String userId, String deckId, String cardId) async {
    final batch = _firestore.batch();

    batch.delete(_cardRef(userId, deckId).doc(cardId));
    batch.update(_deckRef(userId, deckId), {
      'cardCount': FieldValue.increment(-1),
      'updatedAt': Timestamp.now(),
    });

    await batch.commit();
  }

  String _buildDefaultExplanation(String answerText) {
    if (answerText.trim().isEmpty) {
      return 'Penjelasan belum tersedia.';
    }
    return 'Jawaban yang benar adalah: $answerText';
  }
}
