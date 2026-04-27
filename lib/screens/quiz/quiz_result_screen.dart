import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:quiz_flashcard/helpers/quiz_helper.dart';
import 'package:quiz_flashcard/models/deck_model.dart';
import 'package:quiz_flashcard/models/quiz_session_model.dart';
import 'package:quiz_flashcard/screens/quiz/quiz_review_screen.dart';
import 'package:quiz_flashcard/services/quiz_service.dart';

class QuizResultScreen extends StatefulWidget {
  final QuizSessionModel session;
  final DeckModel deck;

  const QuizResultScreen({
    super.key,
    required this.session,
    required this.deck,
  });

  @override
  State<QuizResultScreen> createState() => _QuizResultScreenState();
}

class _QuizResultScreenState extends State<QuizResultScreen> {
  final QuizService _quizService = QuizService();
  bool _isSaving = false;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _saveSession();
  }

  Future<void> _saveSession() async {
    if (_saved) {
      return;
    }

    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await _quizService.saveQuizSession(user.uid, widget.session);
      _saved = true;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Riwayat quiz tersimpan')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal simpan riwayat: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double score = widget.session.scorePercent;
    final String scoreLabel = QuizHelper.getScoreLabel(score);

    return Scaffold(
      appBar: AppBar(title: const Text('Hasil Quiz')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    widget.session.deckTitle,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 14),
                  Icon(
                    score >= 80
                        ? Icons.emoji_events
                        : score >= 50
                            ? Icons.thumb_up_outlined
                            : Icons.refresh,
                    size: 48,
                    color: score >= 80
                        ? Colors.amber
                        : score >= 50
                            ? Colors.blue
                            : Colors.red,
                  ),
                  const SizedBox(height: 8),
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: score),
                    duration: const Duration(milliseconds: 900),
                    builder: (BuildContext _, double value, Widget? child) {
                      final Color scoreColor = score >= 80
                          ? Colors.green
                          : score >= 50
                              ? Colors.orange
                              : Colors.red;
                      return Text(
                        '${value.toStringAsFixed(1)}%',
                        style:
                            Theme.of(context).textTheme.displaySmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: scoreColor,
                                ),
                      );
                    },
                  ),
                  const SizedBox(height: 4),
                  Text(
                    scoreLabel,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _ResultStatCard(
                label: 'Poin',
                value: widget.session.totalPointsEarned,
                color: Colors.green,
              ),
              const SizedBox(width: 8),
              _ResultStatCard(
                label: 'Maks',
                value: widget.session.totalMaxPoints,
                color: Colors.red,
              ),
              const SizedBox(width: 8),
              _ResultStatCard(
                label: 'Clue',
                value: widget.session.totalCluesRevealed,
                color: Colors.orange,
              ),
            ],
          ),
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Center(child: CircularProgressIndicator()),
            ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => QuizReviewScreen(session: widget.session),
                  ),
                );
              },
              child: const Text('Periksa Jawaban'),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Mulai Ulang'),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () {
                int popCount = 0;
                Navigator.of(context).popUntil((Route<dynamic> route) {
                  return popCount++ >= 2;
                });
              },
              child: const Text('Kembali ke Deck'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultStatCard extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _ResultStatCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(
              '$value',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
