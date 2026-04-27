class QuizAnswerModel {
  final String cardId;
  final String question;
  final String answerText;
  final String explanation;
  final List<String> revealedClues;
  final int pointsEarned;
  final int maxPoints;
  final int timeSpentSeconds;
  final bool answerRevealed;
  final int selectedIndex; // legacy
  final int correctIndex; // legacy
  final bool isCorrect; // legacy

  const QuizAnswerModel({
    required this.cardId,
    required this.question,
    required this.answerText,
    required this.explanation,
    required this.revealedClues,
    required this.pointsEarned,
    required this.maxPoints,
    required this.timeSpentSeconds,
    this.answerRevealed = false,
    this.selectedIndex = -1,
    this.correctIndex = 0,
    this.isCorrect = true,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'cardId': cardId,
      'question': question,
      'answerText': answerText,
      'explanation': explanation,
      'revealedClues': revealedClues,
      'pointsEarned': pointsEarned,
      'maxPoints': maxPoints,
      'answerRevealed': answerRevealed,
      'selectedIndex': selectedIndex,
      'correctIndex': correctIndex,
      'isCorrect': isCorrect,
      'timeSpentSeconds': timeSpentSeconds,
    };
  }

  factory QuizAnswerModel.fromMap(Map<String, dynamic> map) {
    final List<String> clues =
        List<String>.from((map['revealedClues'] ?? <String>[]) as List);
    return QuizAnswerModel(
      cardId: (map['cardId'] ?? '') as String,
      question: (map['question'] ?? '') as String,
      answerText: (map['answerText'] ?? '') as String,
      explanation: (map['explanation'] ?? '') as String,
      revealedClues: clues,
      pointsEarned: (map['pointsEarned'] ?? 0) as int,
      maxPoints: (map['maxPoints'] ?? 100) as int,
      timeSpentSeconds: (map['timeSpentSeconds'] ?? 0) as int,
      answerRevealed: (map['answerRevealed'] ?? false) as bool,
      selectedIndex: (map['selectedIndex'] ?? -1) as int,
      correctIndex: (map['correctIndex'] ?? 0) as int,
      isCorrect: (map['isCorrect'] ?? true) as bool,
    );
  }
}
