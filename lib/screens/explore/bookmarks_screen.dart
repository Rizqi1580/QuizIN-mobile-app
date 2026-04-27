import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:quiz_flashcard/models/deck_model.dart';
import 'package:quiz_flashcard/screens/explore/explore_screen.dart';
import 'package:quiz_flashcard/screens/quiz/quiz_start_screen.dart';
import 'package:quiz_flashcard/services/bookmark_service.dart';

class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({super.key});

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  final BookmarkService _bookmarkService = BookmarkService();

  Future<void> _removeBookmark(String userId, String deckId) async {
    try {
      await _bookmarkService.removeBookmark(userId, deckId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bookmark dihapus')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menghapus bookmark: $e')),
      );
    }
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
      appBar: AppBar(
        title: const Text('Deck Tersimpan'),
      ),
      body: StreamBuilder<List<DeckModel>>(
        stream: _bookmarkService.getBookmarks(user.uid),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final bookmarks = snapshot.data!;

          if (bookmarks.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.bookmark_border,
                      size: 64, color: Colors.grey),
                  const SizedBox(height: 12),
                  const Text(
                    'Belum ada deck yang disimpan',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ExploreScreen()),
                    ),
                    icon: const Icon(Icons.explore),
                    label: const Text('Explore Deck'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: bookmarks.length,
            itemBuilder: (context, index) {
              final deck = bookmarks[index];

              return Dismissible(
                key: ValueKey(deck.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.bookmark_remove, color: Colors.white),
                      SizedBox(height: 4),
                      Text('Hapus',
                          style: TextStyle(
                              color: Colors.white, fontSize: 12)),
                    ],
                  ),
                ),
                confirmDismiss: (_) async {
                  return await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Hapus Bookmark'),
                      content: Text(
                          'Hapus "${deck.title}" dari tersimpan?'),
                      actions: [
                        TextButton(
                          onPressed: () =>
                              Navigator.pop(ctx, false),
                          child: const Text('Batal'),
                        ),
                        ElevatedButton(
                          onPressed: () =>
                              Navigator.pop(ctx, true),
                          child: const Text('Hapus'),
                        ),
                      ],
                    ),
                  );
                },
                onDismissed: (_) =>
                    _removeBookmark(user.uid, deck.id),
                child: DeckExploreCard(
                  deck: deck,
                  currentUserId: user.uid,
                  bookmarkService: _bookmarkService,
                  onToggleBookmark: (_) =>
                      _removeBookmark(user.uid, deck.id),
                  onStartQuiz: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => QuizStartScreen(
                        deck: deck,
                        ownerId: deck.ownerId,
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