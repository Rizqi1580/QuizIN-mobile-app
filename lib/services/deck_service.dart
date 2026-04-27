import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:quiz_flashcard/models/deck_model.dart';
import 'package:quiz_flashcard/models/card_model.dart';

class DeckService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> _userDeckRef(String userId) {
    return _firestore.collection('users').doc(userId).collection('decks');
  }

  Future<void> createDeck(DeckModel deck) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('User is not authenticated');
    }

    final ownerId = deck.ownerId.isEmpty ? currentUser.uid : deck.ownerId;
    final now = Timestamp.now();
    final ref = deck.id.isEmpty
        ? _userDeckRef(ownerId).doc()
        : _userDeckRef(ownerId).doc(deck.id);

    final payload = deck
        .copyWith(
          id: ref.id,
          ownerId: ownerId,
          ownerName: deck.ownerName.isEmpty
              ? (currentUser.displayName ?? currentUser.email ?? 'Unknown')
              : deck.ownerName,
          createdAt: deck.createdAt,
          updatedAt: now,
        )
        .toMap();

    payload['createdAt'] = deck.id.isEmpty ? now : deck.createdAt;
    await ref.set(payload);
  }

  Stream<List<DeckModel>> getUserDecks(String userId) {
    return _userDeckRef(userId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => DeckModel.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  Stream<List<DeckModel>> getPublicDecks() {
    return _firestore
        .collectionGroup('decks')
        .where('isPublic', isEqualTo: true)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => DeckModel.fromMap(doc.id, doc.data())).toList());
  }

  Stream<List<DeckModel>> searchPublicDecks(String query) {
    final q = query.toLowerCase().trim();
    return getPublicDecks().map((decks) => decks
        .where((deck) =>
            deck.title.toLowerCase().contains(q) ||
            deck.category.toLowerCase().contains(q))
        .toList());
  }

  Stream<List<CardModel>> getPublicDeckCards(String ownerId, String deckId) {
    return _firestore
        .collection('users')
        .doc(ownerId)
        .collection('decks')
        .doc(deckId)
        .collection('cards')
        .orderBy('createdAt')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => CardModel.fromMap(doc.id, doc.data())).toList());
  }

  Future<void> updateDeck(String deckId, Map<String, dynamic> data) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('User is not authenticated');
    }

    final payload = <String, dynamic>{...data, 'updatedAt': Timestamp.now()};
    await _userDeckRef(currentUser.uid).doc(deckId).update(payload);
  }

  Future<void> deleteDeck(String userId, String deckId) async {
    final deckRef = _userDeckRef(userId).doc(deckId);
    final cardsRef = deckRef.collection('cards');

    final cardsSnapshot = await cardsRef.get();
    final batch = _firestore.batch();

    for (final doc in cardsSnapshot.docs) {
      batch.delete(doc.reference);
    }

    batch.delete(deckRef);
    await batch.commit();
  }
}
