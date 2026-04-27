import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

class QuizTestGenerator {
  final FirebaseFirestore _firestore;
  final Random _random;

  QuizTestGenerator({FirebaseFirestore? firestore, Random? random})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _random = random ?? Random();

  static const List<Map<String, dynamic>> _questionBank = <Map<String, dynamic>>[
    {
      'question': 'Apa ibu kota Indonesia?',
      'answerText': 'Jakarta',
      'clues': <String>['Kota pemerintahan', 'Ada Monas', 'Berada di Pulau Jawa'],
      'explanation': 'Jakarta adalah ibu kota dan pusat pemerintahan Indonesia.',
    },
    {
      'question': 'Hasil dari 12 x 8 adalah?',
      'answerText': '96',
      'clues': <String>['Perkalian dasar', 'Lebih kecil dari 100', '12 dikali 8'],
      'explanation': '12 x 8 = 96 berdasarkan operasi perkalian dasar.',
    },
    {
      'question': 'Planet terbesar di tata surya adalah?',
      'answerText': 'Jupiter',
      'clues': <String>['Planet gas raksasa', 'Punya bintik merah besar', 'Planet kelima dari Matahari'],
      'explanation': 'Jupiter adalah planet terbesar di tata surya.',
    },
    {
      'question': 'Siapa penemu lampu pijar?',
      'answerText': 'Thomas Edison',
      'clues': <String>['Nama terkenal di bidang listrik', 'Bukan Newton', 'Sosok inovator'],
      'explanation': 'Thomas Edison dikenal luas sebagai penemu dan pengembang lampu pijar.',
    },
    {
      'question': 'Bahasa pemrograman Flutter adalah?',
      'answerText': 'Dart',
      'clues': <String>['Bahasa buatan Google', 'Dipakai untuk Flutter', 'Sintaks mirip C-like'],
      'explanation': 'Flutter menggunakan bahasa Dart untuk menulis aplikasi.',
    },
    {
      'question': '2^5 bernilai?',
      'answerText': '32',
      'clues': <String>['Pangkat 5', 'Hasilnya di atas 30', '2 × 2 × 2 × 2 × 2'],
      'explanation': '2 pangkat 5 berarti 2 dikalikan dengan dirinya sendiri 5 kali.',
    },
    {
      'question': 'Satuan arus listrik adalah?',
      'answerText': 'Ampere',
      'clues': <String>['Disingkat A', 'Mengukur arus', 'Bukan tegangan'],
      'explanation': 'Ampere adalah satuan untuk arus listrik.',
    },
    {
      'question': 'Laut terluas di dunia adalah?',
      'answerText': 'Samudra Pasifik',
      'clues': <String>['Paling luas di dunia', 'Ada di antara Asia dan Amerika', 'Nama lain Pacific Ocean'],
      'explanation': 'Samudra Pasifik adalah samudra terluas di dunia.',
    },
  ];

  /// Generate 1 deck test + sejumlah kartu quiz ke Firestore.
  ///
  /// Return: `deckId` yang baru dibuat.
  Future<String> generateQuizTest({
    required String userId,
    required String ownerName,
    String title = 'Deck Test Otomatis',
    String description = 'Deck hasil generate untuk testing quiz mode',
    String category = 'Testing',
    bool isPublic = false,
    int cardCount = 10,
  }) async {
    if (cardCount < 2) {
      throw ArgumentError('cardCount minimal 2');
    }

    final DocumentReference<Map<String, dynamic>> deckRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('decks')
        .doc();

    final Timestamp now = Timestamp.now();

    await deckRef.set(<String, dynamic>{
      'title': title,
      'description': description,
      'category': category,
      'isPublic': isPublic,
      'createdAt': now,
      'updatedAt': now,
      'cardCount': cardCount,
      'ownerId': userId,
      'ownerName': ownerName,
    });

    final WriteBatch batch = _firestore.batch();

    for (int i = 0; i < cardCount; i++) {
      final Map<String, dynamic> raw =
          _questionBank[_random.nextInt(_questionBank.length)];

      final DocumentReference<Map<String, dynamic>> cardRef =
          deckRef.collection('cards').doc();

      batch.set(cardRef, <String, dynamic>{
        'question': '${raw['question']} (Test ${i + 1})',
        'answerText': raw['answerText'],
        'clues': raw['clues'],
        'explanation': raw['explanation'],
        'createdAt': Timestamp.now(),
      });
    }

    await batch.commit();
    return deckRef.id;
  }
}
