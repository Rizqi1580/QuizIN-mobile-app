import 'package:cloud_firestore/cloud_firestore.dart';

class CardModel {
  final String id;
  final String question;
  final String answerText;
  final List<String> clues;
  final String explanation;
  final Timestamp createdAt;
  final String? imageUrl;

  const CardModel({
    this.id = '',
    required this.question,
    required this.answerText,
    required this.clues,
    required this.explanation,
    required this.createdAt,
    this.imageUrl,
  });

  factory CardModel.fromMap(String id, Map<String, dynamic> map) {
    final List<String> legacyOptions =
        List<String>.from((map['options'] ?? <String>[]) as List);
    final int legacyCorrectIndex = (map['correctIndex'] ?? 0) as int;
    final String legacyAnswer = legacyOptions.isNotEmpty &&
            legacyCorrectIndex >= 0 &&
            legacyCorrectIndex < legacyOptions.length
        ? legacyOptions[legacyCorrectIndex]
        : '';

    final List<String> clueList = (map['clues'] ?? <String>[])
            is List
        ? List<String>.from((map['clues'] ?? <String>[]) as List)
        : <String>[];

    return CardModel(
      id: id,
      question: (map['question'] ?? '') as String,
      answerText: (map['answerText'] ?? legacyAnswer) as String,
      clues: clueList.isNotEmpty
          ? clueList
          : legacyOptions
              .where((String option) => option.trim() != legacyAnswer.trim())
              .toList(),
      createdAt: (map['createdAt'] ?? Timestamp.now()) as Timestamp,
      imageUrl: map['imageUrl'] as String?,
      explanation: (map['explanation'] ?? '') as String,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'question': question,
      'answerText': answerText,
      'clues': clues,
      'createdAt': createdAt,
      if (imageUrl != null) 'imageUrl': imageUrl,
      'explanation': explanation,
    };
  }

  CardModel copyWith({
    String? id,
    String? question,
    String? answerText,
    List<String>? clues,
    Timestamp? createdAt,
    String? imageUrl,
    bool clearImage = false,
    String? explanation,
  }) {
    return CardModel(
      id: id ?? this.id,
      question: question ?? this.question,
      answerText: answerText ?? this.answerText,
      clues: clues ?? this.clues,
      createdAt: createdAt ?? this.createdAt,
      imageUrl: clearImage ? null : (imageUrl ?? this.imageUrl),
      explanation: explanation ?? this.explanation,
    );
  }

  @Deprecated('Use answerText')
  List<String> get options => <String>[answerText, ...clues];

  @Deprecated('Flashcard mode no longer uses correctIndex')
  int get correctIndex => 0;
}