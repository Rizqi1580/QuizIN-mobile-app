import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:quiz_flashcard/models/quiz_session_model.dart';

class QuizService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _historyRef(String userId) {
    return _firestore.collection('users').doc(userId).collection('quiz_history');
  }

  Future<void> saveQuizSession(String userId, QuizSessionModel session) async {
    await _historyRef(userId).add(session.toMap());
  }

  Stream<List<QuizSessionModel>> getQuizHistory(String userId) {
    return _historyRef(userId)
        .orderBy('startedAt', descending: true)
        .snapshots()
        .map((QuerySnapshot<Map<String, dynamic>> snapshot) {
      return snapshot.docs
          .map((QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
              QuizSessionModel.fromMap(doc.id, doc.data()))
          .toList();
    });
  }
}
