import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:quiz_flashcard/models/card_model.dart';
import 'package:quiz_flashcard/models/deck_model.dart';
import 'package:quiz_flashcard/screens/quiz/quiz_play_screen.dart';
import 'package:quiz_flashcard/services/card_service.dart';
import 'package:quiz_flashcard/services/deck_service.dart';

class QuizStartScreen extends StatefulWidget {
  final DeckModel deck;
  final String? ownerId;

  const QuizStartScreen({super.key, required this.deck, this.ownerId});

  @override
  State<QuizStartScreen> createState() => _QuizStartScreenState();
}

class _QuizStartScreenState extends State<QuizStartScreen> {
  final CardService _cardService = CardService();
  final DeckService _deckService = DeckService();
  bool _shuffleCards = true;

  /// Apakah ini deck milik orang lain (dibuka dari Explore/Bookmarks)?
  bool get _isOtherUserDeck {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    return widget.ownerId != null && widget.ownerId != currentUserId;
  }

  /// Stream cards yang tepat: milik sendiri atau milik orang lain
  Stream<List<CardModel>> get _cardStream {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    if (_isOtherUserDeck) {
      return _deckService.getPublicDeckCards(
        widget.ownerId!,
        widget.deck.id,
      );
    }

    return _cardService.getCards(currentUserId, widget.deck.id);
  }

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Silakan login terlebih dahulu.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mulai Flashcard'),
        // Tampilkan badge "Deck Orang Lain" jika bukan milik sendiri
        actions: [
          if (_isOtherUserDeck)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Chip(
                avatar: const Icon(Icons.person_outline, size: 16),
                label: Text(
                  widget.deck.ownerName,
                  style: const TextStyle(fontSize: 12),
                ),
                visualDensity: VisualDensity.compact,
              ),
            ),
        ],
      ),
      body: StreamBuilder<List<CardModel>>(
        stream: _cardStream,
        builder: (BuildContext context,
            AsyncSnapshot<List<CardModel>> snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final List<CardModel> cards = snapshot.data!;
          final bool canStart = cards.isNotEmpty;
          final textTheme = Theme.of(context).textTheme;

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  widget.deck.title,
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                if (widget.deck.description.isNotEmpty)
                  Text(
                    widget.deck.description,
                    style: textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[700],
                    ),
                  ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.style_outlined),
                            const SizedBox(width: 8),
                            Text('Total kartu: ${cards.length}'),
                            const Spacer(),
                            Chip(
                              label: Text(widget.deck.isPublic
                                  ? 'Publik'
                                  : 'Privat'),
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SwitchListTile(
                          title: const Text('Acak urutan kartu'),
                          subtitle: const Text('Rekomendasi untuk latihan'),
                          contentPadding: EdgeInsets.zero,
                          value: _shuffleCards,
                          onChanged: (bool value) {
                            setState(() => _shuffleCards = value);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                if (!canStart)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      'Deck butuh minimal 1 kartu untuk mulai flashcard.',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: canStart
                        ? () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => QuizPlayScreen(
                                  deck: widget.deck,
                                  cards: cards,
                                  shuffleCards: _shuffleCards,
                                ),
                              ),
                            );
                          }
                        : null,
                    child: const Text('Mulai Flashcard'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}