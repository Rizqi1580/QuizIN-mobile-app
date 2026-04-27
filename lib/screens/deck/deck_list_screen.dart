import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:quiz_flashcard/models/deck_model.dart';
import 'package:quiz_flashcard/screens/deck/deck_detail_screen.dart';
import 'package:quiz_flashcard/screens/deck/csv_import_screen.dart';
import 'package:quiz_flashcard/screens/deck/deck_form_screen.dart';
import 'package:quiz_flashcard/screens/explore/bookmarks_screen.dart';
import 'package:quiz_flashcard/screens/explore/explore_screen.dart';
import 'package:quiz_flashcard/screens/quiz/quiz_history_screen.dart';
import 'package:quiz_flashcard/screens/quiz/quiz_start_screen.dart';
import 'package:quiz_flashcard/services/deck_service.dart';

class DeckListScreen extends StatefulWidget {
  const DeckListScreen({super.key});

  @override
  State<DeckListScreen> createState() => _DeckListScreenState();
}

class _DeckListScreenState extends State<DeckListScreen> {
  int _currentIndex = 0;

  void _showCreateOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.add_card_outlined),
              title: const Text('Buat Deck Baru'),
              subtitle: const Text('Tambah kartu secara manual'),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const DeckFormScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.upload_file_outlined),
              title: const Text('Import dari CSV'),
              subtitle: const Text('Buat deck otomatis dari file CSV'),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const CsvImportScreen()),
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

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
            label: 'Jelajahi',
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
              onPressed: () => _showCreateOptions(context),
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
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    DeckDetailScreen(deck: deck),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(14, 12, 8, 10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        deck.title,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ),
                                    Chip(
                                      label: Text(deck.isPublic
                                          ? 'Publik'
                                          : 'Privat'),
                                      visualDensity: VisualDensity.compact,
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
                                      icon: const Icon(Icons.edit, size: 20),
                                      tooltip: 'Edit deck',
                                    ),
                                  ],
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(left: 2),
                                  child: Text(
                                    '${deck.cardCount} kartu',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Tooltip(
                                    message: deck.cardCount < 1
                                        ? 'Tambahkan minimal 1 kartu'
                                        : '',
                                    child: FilledButton.icon(
                                      onPressed: deck.cardCount >= 1
                                          ? () => Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      QuizStartScreen(
                                                          deck: deck),
                                                ),
                                              )
                                          : null,
                                      icon: const Icon(Icons.play_arrow,
                                          size: 16),
                                      label: const Text('Mulai'),
                                      style: FilledButton.styleFrom(
                                        visualDensity: VisualDensity.compact,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
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