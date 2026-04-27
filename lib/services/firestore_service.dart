import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final CollectionReference<Map<String, dynamic>> _flashcards =
      FirebaseFirestore.instance.collection('flashcards');

  Stream<QuerySnapshot<Map<String, dynamic>>> getFlashcardsStream(String userId) {
    return _flashcards
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> addFlashcard({
    required String question,
    required String answer,
    required String userId,
  }) {
    return _flashcards.add({
      'question': question,
      'answer': answer,
      'userId': userId,
      'createdAt': Timestamp.now(),
    });
  }

  Future<void> updateFlashcard({
    required String docId,
    required String question,
    required String answer,
  }) {
    return _flashcards.doc(docId).update({
      'question': question,
      'answer': answer,
    });
  }

  Future<void> deleteFlashcard(String docId) {
    return _flashcards.doc(docId).delete();
  }
}
