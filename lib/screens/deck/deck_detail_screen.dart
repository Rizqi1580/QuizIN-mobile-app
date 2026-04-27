import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:quiz_flashcard/models/card_model.dart';
import 'package:quiz_flashcard/models/deck_model.dart';
import 'package:quiz_flashcard/screens/card/card_form_screen.dart';
import 'package:quiz_flashcard/screens/quiz/quiz_start_screen.dart';
import 'package:quiz_flashcard/services/card_service.dart';

class DeckDetailScreen extends StatefulWidget {
  final DeckModel deck;

  const DeckDetailScreen({super.key, required this.deck});

  @override
  State<DeckDetailScreen> createState() => _DeckDetailScreenState();
}

class _DeckDetailScreenState extends State<DeckDetailScreen> {
  final CardService _cardService = CardService();
  bool _isLoading = false;

  Future<void> _deleteCard(String userId, String deckId, String cardId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _cardService.deleteCard(userId, deckId, cardId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kartu berhasil dihapus')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menghapus kartu: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null || user.uid != widget.deck.ownerId) {
      return const Scaffold(
        body: Center(child: Text('Akses ditolak.')), 
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(widget.deck.title)),
      body: Stack(
        children: [
          Column(
            children: [
              Card(
                margin: const EdgeInsets.all(12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.deck.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(widget.deck.description),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Chip(label: Text(widget.deck.category)),
                          const SizedBox(width: 8),
                          Chip(label: Text(widget.deck.isPublic ? 'Public' : 'Private')),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: StreamBuilder<List<CardModel>>(
                  stream: _cardService.getCards(user.uid, widget.deck.id),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }

                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final cards = snapshot.data!;

                    if (cards.isEmpty) {
                      return const Center(
                        child: Text('Belum ada kartu. Tekan + untuk menambah.'),
                      );
                    }

                    return ListView.builder(
                      itemCount: cards.length,
                      itemBuilder: (context, index) {
                        final card = cards[index];
                        return Dismissible(
                          key: ValueKey(card.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            color: Colors.red,
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: const Icon(Icons.delete, color: Colors.white),
                          ),
                          onDismissed: (_) {
                            _deleteCard(user.uid, widget.deck.id, card.id);
                          },
                          child: ListTile(
                            title: Text(card.question),
                            subtitle: Text(
                              'Jawaban: ${card.answerText}\nClue: ${card.clues.length}',
                            ),
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => CardFormScreen(
                                    userId: user.uid,
                                    deckId: widget.deck.id,
                                    card: card,
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
          if (_isLoading)
            Container(
              color: Colors.black12,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CardFormScreen(
                userId: user.uid,
                deckId: widget.deck.id,
              ),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: Tooltip(
          message: widget.deck.cardCount >= 1
              ? 'Mulai flashcard'
              : 'Tambahkan minimal 1 kartu untuk mulai flashcard',
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: widget.deck.cardCount >= 1
                  ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => QuizStartScreen(deck: widget.deck),
                        ),
                      );
                    }
                  : null,
              icon: const Icon(Icons.play_arrow),
                label: const Text('Mulai Flashcard'),
            ),
          ),
        ),
      ),
    );
  }
}
