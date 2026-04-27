import 'package:flutter/material.dart';
import 'package:quiz_flashcard/models/quiz_answer_model.dart';
import 'package:quiz_flashcard/models/quiz_session_model.dart';

class QuizReviewScreen extends StatelessWidget {
  final QuizSessionModel session;

  const QuizReviewScreen({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    final double score = session.scorePercent;

    return Scaffold(
      appBar: AppBar(title: const Text('Review Jawaban')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: session.answers.length + 1,
        separatorBuilder: (_, index) => const SizedBox(height: 10),
        itemBuilder: (BuildContext context, int index) {
          if (index == 0) {
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.deckTitle,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Skor: ${score.toStringAsFixed(1)}%',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _StatChip(
                          label: 'Poin ${session.totalPointsEarned}',
                          color: Colors.green,
                        ),
                        _StatChip(
                          label: 'Maks ${session.totalMaxPoints}',
                          color: Colors.blue,
                        ),
                        _StatChip(
                          label: 'Clue ${session.totalCluesRevealed}',
                          color: Colors.orange,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }

          final QuizAnswerModel answer = session.answers[index - 1];
          final bool answerRevealed = answer.answerRevealed;

          return Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 13,
                        child: Text('$index'),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          answer.question,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (answer.revealedClues.isNotEmpty) ...[
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: answer.revealedClues
                          .map(
                            (clue) => _StatChip(
                              label: clue,
                              color: Colors.orange,
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 10),
                  ],
                  Text(
                    answerRevealed ? 'Jawaban dibuka' : 'Jawaban belum dibuka',
                    style: TextStyle(
                      color: answerRevealed ? Colors.green : Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('Poin: ${answer.pointsEarned}/${answer.maxPoints}'),
                  const SizedBox(height: 4),
                  Text('Waktu: ${answer.timeSpentSeconds} detik'),
                  const SizedBox(height: 8),
                  Text(
                    answer.answerText,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(answer.explanation),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StatChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
