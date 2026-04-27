import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:quiz_flashcard/helpers/quiz_helper.dart';
import 'package:quiz_flashcard/models/card_model.dart';
import 'package:quiz_flashcard/models/deck_model.dart';
import 'package:quiz_flashcard/models/quiz_answer_model.dart';
import 'package:quiz_flashcard/models/quiz_session_model.dart';
import 'package:quiz_flashcard/screens/quiz/quiz_result_screen.dart';
import 'package:quiz_flashcard/services/storage_service.dart';

class QuizPlayScreen extends StatefulWidget {
  final DeckModel deck;
  final List<CardModel> cards;
  final bool shuffleCards;

  const QuizPlayScreen({
    super.key,
    required this.deck,
    required this.cards,
    required this.shuffleCards,
  });

  @override
  State<QuizPlayScreen> createState() => _QuizPlayScreenState();
}

class _QuizPlayScreenState extends State<QuizPlayScreen>
    with SingleTickerProviderStateMixin {
  late final DateTime _startedAt;
  late final List<CardModel> _cards;

  final Stopwatch _stopwatch = Stopwatch();
  final List<QuizAnswerModel> _answers = <QuizAnswerModel>[];

  late AnimationController _flipController;
  late Timer _timerTicker;

  int _currentIndex = 0;
  bool _showAnswer = false;
  final Set<int> _revealedClueIndexes = <int>{};

  @override
  void initState() {
    super.initState();
    _startedAt = DateTime.now();

    _cards = widget.shuffleCards
        ? QuizHelper.shuffleCards(widget.cards)
        : List<CardModel>.from(widget.cards);

    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );

    _startTimer();

    _timerTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _flipController.dispose();
    _timerTicker.cancel();
    _stopwatch.stop();
    super.dispose();
  }

  void _startTimer() {
    _stopwatch
      ..reset()
      ..start();
  }

  Future<bool> _confirmLeaveQuiz() async {
    final bool shouldLeave = await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Keluar dari flashcard?'),
              content: const Text('Progress kamu akan hilang.'),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Batal'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Keluar'),
                ),
              ],
            );
          },
        ) ??
        false;
    return shouldLeave;
  }

  CardModel get _currentCard => _cards[_currentIndex];

  int get _total => _cards.length;
  bool get _isLastCard => _currentIndex == _total - 1;

  int get _currentCardPoints =>
      QuizHelper.calculateCardPoints(_revealedClueIndexes.length);

  int get _earnedPointsSoFar => _answers.fold<int>(
        0,
        (int total, QuizAnswerModel answer) => total + answer.pointsEarned,
      );

  void _revealClue(int clueIndex) {
    if (_showAnswer) return;
    if (clueIndex < 0 || clueIndex >= _currentCard.clues.length) return;

    final bool added = _revealedClueIndexes.add(clueIndex);
    if (added) setState(() {});
  }

  void _toggleAnswerReveal() {
    setState(() => _showAnswer = !_showAnswer);
    if (_showAnswer) {
      _flipController.forward();
    } else {
      _flipController.reverse();
    }
  }

  void _finishCurrentCard() {
    final CardModel card = _currentCard;
    final int earnedPoints = _currentCardPoints;
    final List<String> revealedClues = _revealedClueIndexes
        .map((int index) => card.clues[index])
        .toList();

    _answers.add(
      QuizAnswerModel(
        cardId: card.id,
        question: card.question,
        answerText: card.answerText,
        explanation: card.explanation,
        revealedClues: revealedClues,
        pointsEarned: earnedPoints,
        maxPoints: QuizHelper.maxPointsPerCard,
        timeSpentSeconds: _stopwatch.elapsed.inSeconds,
        answerRevealed: _showAnswer,
      ),
    );

    _stopwatch.stop();

    if (_isLastCard) {
      final QuizSessionModel session = QuizSessionModel(
        deckId: widget.deck.id,
        deckTitle: widget.deck.title,
        totalCards: _total,
        correctCount: 0,
        wrongCount: 0,
        skippedCount: 0,
        startedAt: _startedAt,
        finishedAt: DateTime.now(),
        answers: List<QuizAnswerModel>.from(_answers),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => QuizResultScreen(session: session, deck: widget.deck),
        ),
      );
      return;
    }

    setState(() {
      _currentIndex++;
      _showAnswer = false;
      _revealedClueIndexes.clear();
    });
    _flipController.reset();
    _startTimer();
  }

  // ── Card faces ────────────────────────────────────────────────────────────

  Widget _buildCardFront(BuildContext context) {
    final CardModel card = _currentCard;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (card.imageUrl != null && card.imageUrl!.isNotEmpty)
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: _buildCardImage(card.imageUrl!),
          ),
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pertanyaan',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
              const SizedBox(height: 10),
              Text(
                card.question,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      height: 1.35,
                    ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.touch_app_outlined,
                    size: 14,
                    color: Colors.grey[500],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Tap "Reveal Answer" untuk membalik kartu',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCardBack(BuildContext context) {
    final CardModel card = _currentCard;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Jawaban',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            card.answerText,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
          ),
          if (card.explanation.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Divider(),
            const SizedBox(height: 10),
            Text(
              card.explanation,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    height: 1.55,
                  ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCardImage(String imageUrl) {
    if (!StorageService.isLocalPath(imageUrl)) {
      return _buildImagePlaceholder();
    }
    final file = File(imageUrl);
    if (!file.existsSync()) return _buildImagePlaceholder();
    return Image.file(
      file,
      height: 180,
      width: double.infinity,
      fit: BoxFit.cover,
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      height: 120,
      width: double.infinity,
      color: Colors.grey[100],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image_not_supported_outlined,
              color: Colors.grey[400], size: 32),
          const SizedBox(height: 6),
          Text(
            'Gambar tidak tersedia',
            style: TextStyle(color: Colors.grey[500], fontSize: 12),
          ),
        ],
      ),
    );
  }

  // ── Flashcard flip widget ─────────────────────────────────────────────────

  Widget _buildFlashCard(BuildContext context) {
    return AnimatedBuilder(
      animation: _flipController,
      builder: (BuildContext ctx, Widget? _) {
        final double angle = _flipController.value * math.pi;
        final bool showBack = _flipController.value > 0.5;

        return IgnorePointer(
          // Disable taps while mid-flip to prevent double-triggers
          ignoring: _flipController.isAnimating,
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(angle),
            child: Container(
              constraints: const BoxConstraints(minHeight: 160),
              decoration: BoxDecoration(
                color: showBack
                    ? Theme.of(ctx).colorScheme.primaryContainer
                    : Theme.of(ctx).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: showBack
                      ? Theme.of(ctx).colorScheme.primary.withValues(alpha: 0.35)
                      : Theme.of(ctx).colorScheme.outlineVariant,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.07),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: showBack
                  ? Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()..rotateY(math.pi),
                      child: _buildCardBack(ctx),
                    )
                  : _buildCardFront(ctx),
            ),
          ),
        );
      },
    );
  }

  // ── Clue section (front only) ─────────────────────────────────────────────

  Widget _buildClueSection(BuildContext context) {
    final List<String> clues = _currentCard.clues;
    if (clues.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.lightbulb_outline, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Clue',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const Spacer(),
                Text(
                  '${_revealedClueIndexes.length}/${clues.length}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              'Setiap clue -${QuizHelper.cluePenaltyPerReveal} poin',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List<Widget>.generate(clues.length, (int index) {
                final bool revealed = _revealedClueIndexes.contains(index);
                return ActionChip(
                  avatar: Icon(
                    revealed ? Icons.visibility : Icons.lock_outline,
                    size: 16,
                    color: revealed
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey[600],
                  ),
                  label: Text(
                    revealed ? clues[index] : 'Clue ${index + 1}',
                  ),
                  onPressed: revealed ? null : () => _revealClue(index),
                );
              }),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.payments_outlined, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Poin saat ini: $_currentCardPoints/${QuizHelper.maxPointsPerCard}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Revealed clues summary (back only) ───────────────────────────────────

  Widget _buildRevealedCluesSummary(BuildContext context) {
    final List<String> revealed = _revealedClueIndexes
        .map((int i) => _currentCard.clues[i])
        .toList();

    if (revealed.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Clue yang dibuka',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: revealed
                  .map(
                    (String clue) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                            color: Colors.orange.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        clue,
                        style: const TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  // ── Stat chip ─────────────────────────────────────────────────────────────

  Widget _buildStatChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              '$label: $value',
              style: TextStyle(fontWeight: FontWeight.w600, color: color),
            ),
          ],
        ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_cards.isEmpty) {
      return const Scaffold(body: Center(child: Text('Deck kosong.')));
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) return;
        final bool shouldLeave = await _confirmLeaveQuiz();
        if (!context.mounted || !shouldLeave) return;
        Navigator.pop(context);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.deck.title),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              final bool shouldLeave = await _confirmLeaveQuiz();
              if (!context.mounted || !shouldLeave) return;
              Navigator.pop(context);
            },
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Progress ──
            Text(
              'Kartu ${_currentIndex + 1} dari $_total',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                minHeight: 8,
                value: (_currentIndex + 1) / _total,
              ),
            ),
            const SizedBox(height: 12),

            // ── Stats row ──
            Row(
              children: [
                _buildStatChip(
                  context,
                  icon: Icons.timer_outlined,
                  label: 'Waktu',
                  value: '${_stopwatch.elapsed.inSeconds}s',
                  color: Colors.blue,
                ),
                const SizedBox(width: 8),
                _buildStatChip(
                  context,
                  icon: Icons.grade_outlined,
                  label: 'Poin',
                  value: '${_earnedPointsSoFar + _currentCardPoints}',
                  color: Colors.green,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Flashcard (flips) ──
            _buildFlashCard(context),
            const SizedBox(height: 16),

            // ── Below-card content (switches front ↔ back) ──
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 260),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              child: _showAnswer
                  ? _buildBackContent(context)
                  : _buildFrontContent(context),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildFrontContent(BuildContext context) {
    return Column(
      key: const ValueKey<String>('front-content'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildClueSection(context),
        if (_currentCard.clues.isNotEmpty) const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _toggleAnswerReveal,
          icon: const Icon(Icons.flip),
          label: const Text('Reveal Answer'),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: _finishCurrentCard,
          child: const Text('Lewati Kartu'),
        ),
      ],
    );
  }

  Widget _buildBackContent(BuildContext context) {
    return Column(
      key: const ValueKey<String>('back-content'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildRevealedCluesSummary(context),
        if (_revealedClueIndexes.isNotEmpty) const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.stars_outlined, size: 18, color: Colors.green),
              const SizedBox(width: 8),
              Text(
                'Poin kartu ini: $_currentCardPoints/${QuizHelper.maxPointsPerCard}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _toggleAnswerReveal,
                child: const Text('Sembunyikan'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: _finishCurrentCard,
                child: Text(_isLastCard ? 'Selesai' : 'Kartu Berikutnya'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
