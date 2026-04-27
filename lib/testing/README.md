# Testing Utilities

Folder ini berisi utilitas untuk generate data quiz test ke Firestore.

## File

- `quiz_test_generator.dart`
  - `QuizTestGenerator.generateQuizTest(...)`

## Contoh pakai cepat

```dart
final generator = QuizTestGenerator();

final deckId = await generator.generateQuizTest(
  userId: user.uid,
  ownerName: user.displayName ?? user.email ?? 'Unknown',
  title: 'Deck Uji Coba',
  cardCount: 10,
);

print('Generated deck: $deckId');
```

## Catatan

- Deck dibuat di path: `users/{userId}/decks/{deckId}`
- Cards dibuat di path: `users/{userId}/decks/{deckId}/cards/{cardId}`
- `cardCount` minimal 2.
