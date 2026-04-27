import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:quiz_flashcard/models/deck_model.dart';

class BookmarkService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _bookmarksRef(String userId) =>
      _firestore.collection('users').doc(userId).collection('bookmarks');

  /// Simpan deck ke bookmark user
  Future<void> addBookmark(String userId, DeckModel deck) async {
    await _bookmarksRef(userId).doc(deck.id).set({
      'deckId': deck.id,
      'ownerId': deck.ownerId,
      'title': deck.title,
      'description': deck.description,
      'category': deck.category,
      'cardCount': deck.cardCount,
      'ownerName': deck.ownerName,
      'savedAt': Timestamp.now(),
    });
  }

  /// Hapus deck dari bookmark user
  Future<void> removeBookmark(String userId, String deckId) async {
    await _bookmarksRef(userId).doc(deckId).delete();
  }

  /// Stream semua bookmark user sebagai List of DeckModel
  Stream<List<DeckModel>> getBookmarks(String userId) {
    return _bookmarksRef(userId)
        .orderBy('savedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              return DeckModel(
                id: data['deckId'] as String,
                title: data['title'] as String,
                description: data['description'] as String? ?? '',
                category: data['category'] as String? ?? '',
                isPublic: true,
                createdAt: data['savedAt'] as Timestamp,
                updatedAt: data['savedAt'] as Timestamp,
                cardCount: data['cardCount'] as int? ?? 0,
                ownerId: data['ownerId'] as String,
                ownerName: data['ownerName'] as String? ?? 'Unknown',
              );
            }).toList());
  }

  /// Stream bool — apakah deck sudah di-bookmark oleh user?
  Stream<bool> isBookmarked(String userId, String deckId) {
    return _bookmarksRef(userId).doc(deckId).snapshots().map(
          (doc) => doc.exists,
        );
  }
}