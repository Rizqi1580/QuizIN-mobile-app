import 'package:cloud_firestore/cloud_firestore.dart';

class DeckModel {
  final String id;
  final String title;
  final String description;
  final String category;
  final bool isPublic;
  final Timestamp createdAt;
  final Timestamp updatedAt;
  final int cardCount;
  final String ownerId;
  final String ownerName;

  const DeckModel({
    this.id = '',
    required this.title,
    required this.description,
    required this.category,
    required this.isPublic,
    required this.createdAt,
    required this.updatedAt,
    required this.cardCount,
    required this.ownerId,
    required this.ownerName,
  });

  factory DeckModel.fromMap(String id, Map<String, dynamic> map) {
    return DeckModel(
      id: id,
      title: (map['title'] ?? '') as String,
      description: (map['description'] ?? '') as String,
      category: (map['category'] ?? 'Lainnya') as String,
      isPublic: (map['isPublic'] ?? false) as bool,
      createdAt: (map['createdAt'] ?? Timestamp.now()) as Timestamp,
      updatedAt: (map['updatedAt'] ?? Timestamp.now()) as Timestamp,
      cardCount: (map['cardCount'] ?? 0) as int,
      ownerId: (map['ownerId'] ?? '') as String,
      ownerName: (map['ownerName'] ?? '') as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'isPublic': isPublic,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'cardCount': cardCount,
      'ownerId': ownerId,
      'ownerName': ownerName,
    };
  }

  DeckModel copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    bool? isPublic,
    Timestamp? createdAt,
    Timestamp? updatedAt,
    int? cardCount,
    String? ownerId,
    String? ownerName,
  }) {
    return DeckModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      isPublic: isPublic ?? this.isPublic,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      cardCount: cardCount ?? this.cardCount,
      ownerId: ownerId ?? this.ownerId,
      ownerName: ownerName ?? this.ownerName,
    );
  }
}
