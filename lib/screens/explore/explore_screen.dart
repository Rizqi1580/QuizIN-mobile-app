import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:quiz_flashcard/models/deck_model.dart';
import 'package:quiz_flashcard/screens/quiz/quiz_start_screen.dart';
import 'package:quiz_flashcard/services/bookmark_service.dart';
import 'package:quiz_flashcard/services/deck_service.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final DeckService _deckService = DeckService();
  final BookmarkService _bookmarkService = BookmarkService();
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  String _selectedCategory = 'Semua';
  Timer? _debounce;

  static const List<String> _categories = [
    'Semua',
    'Matematika',
    'Sains',
    'Bahasa',
    'Sejarah',
    'Pemrograman',
    'Lainnya',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (mounted) {
        setState(() => _searchQuery = value.trim().toLowerCase());
      }
    });
  }

  List<DeckModel> _applyFilters(List<DeckModel> decks, String currentUserId) {
    return decks.where((deck) {
      // Jangan tampilkan deck milik sendiri
      if (deck.ownerId == currentUserId) return false;

      // Filter kategori
      if (_selectedCategory != 'Semua' &&
          deck.category.toLowerCase() != _selectedCategory.toLowerCase()) {
        return false;
      }

      // Filter search query
      if (_searchQuery.isNotEmpty) {
        final matchTitle = deck.title.toLowerCase().contains(_searchQuery);
        final matchCategory =
            deck.category.toLowerCase().contains(_searchQuery);
        if (!matchTitle && !matchCategory) return false;
      }

      return true;
    }).toList();
  }

  Future<void> _toggleBookmark(
      String userId, DeckModel deck, bool isBookmarked) async {
    try {
      if (isBookmarked) {
        await _bookmarkService.removeBookmark(userId, deck.id);
      } else {
        await _bookmarkService.addBookmark(userId, deck);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal update bookmark: $e')),
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
        title: const Text('Jelajahi'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Cari deck atau kategori...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Filter chips
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: _categories.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final selected = _selectedCategory == cat;
                return FilterChip(
                  label: Text(cat),
                  selected: selected,
                  onSelected: (_) =>
                      setState(() => _selectedCategory = cat),
                );
              },
            ),
          ),
          const Divider(height: 1),
          // Deck list
          Expanded(
            child: StreamBuilder<List<DeckModel>>(
              stream: _deckService.getPublicDecks(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final filtered = _applyFilters(snapshot.data!, user.uid);

                if (filtered.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search_off, size: 64, color: Colors.grey),
                        SizedBox(height: 12),
                        Text(
                          'Tidak ada deck publik ditemukan',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final deck = filtered[index];
                    return _DeckExploreCard(
                      deck: deck,
                      currentUserId: user.uid,
                      bookmarkService: _bookmarkService,
                      onToggleBookmark: (isBookmarked) =>
                          _toggleBookmark(user.uid, deck, isBookmarked),
                      onStartQuiz: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => QuizStartScreen(
                            deck: deck,
                            ownerId: deck.ownerId,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget card deck untuk ExploreScreen dan BookmarksScreen
class DeckExploreCard extends StatelessWidget {
  const DeckExploreCard({
    super.key,
    required this.deck,
    required this.currentUserId,
    required this.bookmarkService,
    required this.onToggleBookmark,
    required this.onStartQuiz,
    this.onDismiss,
  });

  final DeckModel deck;
  final String currentUserId;
  final BookmarkService bookmarkService;
  final void Function(bool isCurrentlyBookmarked) onToggleBookmark;
  final VoidCallback onStartQuiz;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    deck.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                // Bookmark toggle
                StreamBuilder<bool>(
                  stream:
                      bookmarkService.isBookmarked(currentUserId, deck.id),
                  builder: (context, snapshot) {
                    final isBookmarked = snapshot.data ?? false;
                    return IconButton(
                      icon: Icon(
                        isBookmarked
                            ? Icons.bookmark
                            : Icons.bookmark_border,
                        color: isBookmarked
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                      tooltip: isBookmarked
                          ? 'Hapus dari tersimpan'
                          : 'Simpan deck',
                      onPressed: () => onToggleBookmark(isBookmarked),
                    );
                  },
                ),
              ],
            ),
            if (deck.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                deck.description,
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.person_outline, size: 14,
                    color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  deck.ownerName,
                  style: const TextStyle(
                      fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(width: 12),
                Chip(
                  label: Text(
                    deck.category.isEmpty ? 'Lainnya' : deck.category,
                    style: const TextStyle(fontSize: 11),
                  ),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
                const SizedBox(width: 12),
                const Icon(Icons.style_outlined, size: 14,
                    color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  '${deck.cardCount} kartu',
                  style: const TextStyle(
                      fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: Tooltip(
                message: deck.cardCount < 1
                    ? 'Tambahkan minimal 1 kartu untuk memulai flashcard'
                    : '',
                child: ElevatedButton.icon(
                  onPressed: deck.cardCount >= 1 ? onStartQuiz : null,
                  icon: const Icon(Icons.play_arrow, size: 18),
                  label: const Text('Mulai Flashcard'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Internal alias agar tidak konflik nama
typedef _DeckExploreCard = DeckExploreCard;