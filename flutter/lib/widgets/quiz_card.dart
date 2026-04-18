import 'package:flutter/material.dart';

class QuizCard extends StatelessWidget {
  const QuizCard({
    required this.question,
    required this.options,
    required this.selected,
    required this.correct,
    required this.answered,
    required this.onTap,
    super.key,
  });

  final String question;
  final List<String> options;
  final String? selected;
  final String correct;
  final bool answered;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(22),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            question,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          ...options.map((String option) {
            final bool isSelected = selected == option;
            final bool isCorrect = option == correct;
            Color border = Colors.transparent;
            Color bg = Theme.of(context).scaffoldBackgroundColor;
            if (answered && isCorrect) {
              border = const Color(0xFF4CAF50);
              bg = const Color(0x1A4CAF50);
            } else if (answered && isSelected && !isCorrect) {
              border = const Color(0xFFF44336);
              bg = const Color(0x1AF44336);
            }

            return AnimatedContainer(
              duration: const Duration(milliseconds: 280),
              margin: const EdgeInsets.only(bottom: 12),
              child: OutlinedButton(
                onPressed: answered ? null : () => onTap(option),
                style: OutlinedButton.styleFrom(
                  backgroundColor: bg,
                  side: BorderSide(color: border, width: 1.5),
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  alignment: Alignment.centerLeft,
                ),
                child: Text(option),
              ),
            );
          }),
        ],
      ),
    );
  }
}
