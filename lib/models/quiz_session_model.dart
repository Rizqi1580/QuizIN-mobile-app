import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:quiz_flashcard/models/quiz_answer_model.dart';

class QuizSessionModel {
  final String id;
  final String deckId;
  final String deckTitle;
  final int totalCards;
  final int correctCount;
  final int wrongCount;
  final int skippedCount;
  final DateTime startedAt;
  final DateTime? finishedAt;
  final List<QuizAnswerModel> answers;

  const QuizSessionModel({
    this.id = '',
    required this.deckId,
    required this.deckTitle,
    required this.totalCards,
    required this.correctCount,
    required this.wrongCount,
    required this.skippedCount,
    required this.startedAt,
    this.finishedAt,
    required this.answers,
  });

  int get totalPointsEarned =>
      answers.fold<int>(0, (int total, QuizAnswerModel answer) => total + answer.pointsEarned);

  int get totalMaxPoints =>
      answers.fold<int>(0, (int total, QuizAnswerModel answer) => total + answer.maxPoints);

  int get totalCluesRevealed => answers.fold<int>(
        0,
        (int total, QuizAnswerModel answer) => total + answer.revealedClues.length,
      );

  double get scorePercent {
    if (totalMaxPoints <= 0) return 0.0;
    return (totalPointsEarned / totalMaxPoints) * 100.0;
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'deckId': deckId,
      'deckTitle': deckTitle,
      'totalCards': totalCards,
      'correctCount': correctCount,
      'wrongCount': wrongCount,
      'skippedCount': skippedCount,
      'startedAt': Timestamp.fromDate(startedAt),
      'finishedAt': finishedAt == null ? null : Timestamp.fromDate(finishedAt!),
      'answers': answers.map((QuizAnswerModel answer) => answer.toMap()).toList(),
    };
  }

  factory QuizSessionModel.fromMap(String id, Map<String, dynamic> map) {
    DateTime parseDate(dynamic value) {
      if (value is Timestamp) {
        return value.toDate();
      }
      if (value is DateTime) {
        return value;
      }
      return DateTime.now();
    }

    final List<dynamic> rawAnswers = (map['answers'] ?? <dynamic>[]) as List<dynamic>;

    return QuizSessionModel(
      id: id,
      deckId: (map['deckId'] ?? '') as String,
      deckTitle: (map['deckTitle'] ?? '') as String,
      totalCards: (map['totalCards'] ?? 0) as int,
      correctCount: (map['correctCount'] ?? 0) as int,
      wrongCount: (map['wrongCount'] ?? 0) as int,
      skippedCount: (map['skippedCount'] ?? 0) as int,
      startedAt: parseDate(map['startedAt']),
      finishedAt: map['finishedAt'] == null ? null : parseDate(map['finishedAt']),
      answers: rawAnswers
          .map((dynamic e) => QuizAnswerModel.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }
}
