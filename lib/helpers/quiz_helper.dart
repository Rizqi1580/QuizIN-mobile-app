import 'dart:math';

import 'package:quiz_flashcard/models/card_model.dart';

class QuizHelper {
  static const int maxPointsPerCard = 100;
  static const int cluePenaltyPerReveal = 20;

  static List<CardModel> shuffleCards(List<CardModel> cards) {
    final List<CardModel> shuffledCards = List<CardModel>.from(cards);
    shuffledCards.shuffle(Random());
    return shuffledCards;
  }

  static Map<String, dynamic> buildLegacyOptions(CardModel card) {
    return <String, dynamic>{
      'options': <String>[card.answerText, ...card.clues],
      'correctIndex': 0,
    };
  }

  static int calculateCardPoints(int cluesRevealed) {
    final int points = maxPointsPerCard - (cluesRevealed * cluePenaltyPerReveal);
    return points.clamp(0, maxPointsPerCard);
  }

  static double calculateScore(int earnedPoints, int maxPoints) {
    if (maxPoints <= 0) {
      return 0.0;
    }

    return (earnedPoints / maxPoints) * 100.0;
  }

  static String getScoreLabel(double score) {
    if (score >= 80) {
      return 'Mantap';
    }
    if (score >= 60) {
      return 'Bagus, masih bisa ditingkatkan';
    }
    return 'Perlu latihan lagi';
  }
}
