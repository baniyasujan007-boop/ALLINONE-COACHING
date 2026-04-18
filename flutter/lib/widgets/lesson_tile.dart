import 'package:flutter/material.dart';

import '../models/course_model.dart';

class LessonTile extends StatelessWidget {
  const LessonTile({
    required this.lesson,
    required this.onTap,
    this.leading,
    this.trailing,
    this.titleSuffix,
    super.key,
  });

  final LessonItem lesson;
  final VoidCallback onTap;
  final Widget? leading;
  final Widget? trailing;
  final Widget? titleSuffix;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      tileColor: Theme.of(context).cardColor,
      leading: leading ??
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: const LinearGradient(
                colors: <Color>[Color(0xFF6C63FF), Color(0xFF4DA6FF)],
              ),
            ),
            child: const Icon(Icons.play_arrow_rounded, color: Colors.white),
          ),
      title: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              lesson.title,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          if (titleSuffix != null) ...<Widget>[
            const SizedBox(width: 8),
            titleSuffix!,
          ],
        ],
      ),
      subtitle: Text(lesson.duration),
      trailing: trailing ?? const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}
