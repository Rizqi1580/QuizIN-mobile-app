import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:quiz_flashcard/models/deck_model.dart';
import 'package:quiz_flashcard/screens/deck/deck_detail_screen.dart';
import 'package:quiz_flashcard/screens/deck/deck_form_screen.dart';
import 'package:quiz_flashcard/screens/explore/bookmarks_screen.dart';
import 'package:quiz_flashcard/screens/explore/explore_screen.dart';
import 'package:quiz_flashcard/screens/quiz/quiz_history_screen.dart';
import 'package:quiz_flashcard/services/deck_service.dart';

class DeckListScreen extends StatefulWidget {
  const DeckListScreen({super.key});

  @override
  State<DeckListScreen> createState() => _DeckListScreenState();
}

class _DeckListScreenState extends State<DeckListScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Silakan login terlebih dahulu.')),
      );
    }

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          _MyDecksTab(),
          ExploreScreen(),
          BookmarksScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) =>
            setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Deck Saya',
          ),
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore),
            label: 'Explore',
          ),
          NavigationDestination(
            icon: Icon(Icons.bookmark_outline),
            selectedIcon: Icon(Icons.bookmark),
            label: 'Tersimpan',
          ),
        ],
      ),
      // FAB hanya muncul di tab Deck Saya
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DeckFormScreen()),
                );
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}

/// Tab "Deck Saya" — konten dari DeckListScreen lama
class _MyDecksTab extends StatefulWidget {
  const _MyDecksTab();

  @override
  State<_MyDecksTab> createState() => _MyDecksTabState();
}

class _MyDecksTabState extends State<_MyDecksTab> {
  final DeckService _deckService = DeckService();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Deck Saya'),
        actions: [
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const QuizHistoryScreen()),
            ),
            icon: const Icon(Icons.history),
          ),
          IconButton(
            onPressed: () =>
                Navigator.pushNamed(context, 'profile'),
            icon: const Icon(Icons.person),
          ),
        ],
      ),
      body: StreamBuilder<List<DeckModel>>(
            stream: _deckService.getUserDecks(user.uid),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                    child: Text('Error: ${snapshot.error}'));
              }

              if (!snapshot.hasData) {
                return const Center(
                    child: CircularProgressIndicator());
              }

              final decks = snapshot.data!;

              if (decks.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.collections_bookmark_outlined,
                        size: 70,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Belum ada deck. Tekan + untuk membuat deck.',
                        style: TextStyle(color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const DeckFormScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Buat Deck Pertama'),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                itemCount: decks.length,
                itemBuilder: (context, index) {
                  final deck = decks[index];

                  return TweenAnimationBuilder<double>(
                      key: ValueKey('deck_anim_${deck.id}'),
                      tween: Tween<double>(begin: 0, end: 1),
                      duration: Duration(
                        milliseconds: 220 + (index * 45).clamp(0, 220),
                      ),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: value,
                          child: Transform.translate(
                            offset: Offset(0, (1 - value) * 12),
                            child: child,
                          ),
                        );
                      },
                      child: Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          title: Text(deck.title),
                          subtitle:
                              Text('Jumlah kartu: ${deck.cardCount}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Chip(
                                label: Text(deck.isPublic
                                    ? 'Public'
                                    : 'Private'),
                              ),
                              IconButton(
                                onPressed: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          DeckFormScreen(deck: deck),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.edit),
                              ),
                            ],
                          ),
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    DeckDetailScreen(deck: deck),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                },
              );
            },
      ),
    );
  }
}