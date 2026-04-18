import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/student_progress.dart';

class ProgressService extends ChangeNotifier {
  ProgressService._();
  static final ProgressService instance = ProgressService._();
  static const String _storageKey = 'student_progress_by_user';

  final Map<String, StudentProgress> _progressByUserId =
      <String, StudentProgress>{};

  Future<void> restore() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) {
      return;
    }
    try {
      final dynamic decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return;
      }
      _progressByUserId
        ..clear()
        ..addEntries(
          decoded.entries
              .where((MapEntry<dynamic, dynamic> entry) => entry.value is Map)
              .map(
                (MapEntry<dynamic, dynamic> entry) =>
                    MapEntry<String, StudentProgress>(
                      entry.key.toString(),
                      StudentProgress.fromJson(
                        Map<String, dynamic>.from(entry.value as Map),
                      ),
                    ),
              ),
        );
    } catch (_) {
      // Ignore corrupt cached progress and continue with empty state.
    }
  }

  StudentProgress getProgress(String userId) {
    return _progressByUserId.putIfAbsent(
      userId,
      () => StudentProgress(userId: userId),
    );
  }

  void markLessonComplete({required String userId, required String lessonId}) {
    final StudentProgress p = getProgress(userId);
    p.completedLessonIds.add(lessonId);
    _persist();
    notifyListeners();
  }

  bool toggleLessonComplete({
    required String userId,
    required String lessonId,
  }) {
    final StudentProgress p = getProgress(userId);
    if (p.completedLessonIds.contains(lessonId)) {
      p.completedLessonIds.remove(lessonId);
      _persist();
      notifyListeners();
      return false;
    }
    p.completedLessonIds.add(lessonId);
    _persist();
    notifyListeners();
    return true;
  }

  void saveQuizScore({
    required String userId,
    required String courseId,
    required int scorePercent,
  }) {
    final StudentProgress p = getProgress(userId);
    p.quizScoresByCourseId[courseId] = scorePercent;
    _persist();
    notifyListeners();
  }

  Map<String, int> getQuizAnswers({
    required String userId,
    required String courseId,
  }) {
    final StudentProgress p = getProgress(userId);
    return Map<String, int>.unmodifiable(
      p.quizAnswersByCourseId[courseId] ?? <String, int>{},
    );
  }

  void saveQuizAnswer({
    required String userId,
    required String courseId,
    required String questionId,
    required int selectedIndex,
  }) {
    final StudentProgress p = getProgress(userId);
    final Map<String, int> answers = p.quizAnswersByCourseId.putIfAbsent(
      courseId,
      () => <String, int>{},
    );
    answers[questionId] = selectedIndex;
    _persist();
    notifyListeners();
  }

  Map<String, int> getChallengeQuizAnswers({required String userId}) {
    final StudentProgress p = getProgress(userId);
    return Map<String, int>.unmodifiable(p.challengeQuizAnswers);
  }

  void saveChallengeQuizAnswer({
    required String userId,
    required String questionKey,
    required int selectedIndex,
  }) {
    final StudentProgress p = getProgress(userId);
    p.challengeQuizAnswers[questionKey] = selectedIndex;
    _persist();
    notifyListeners();
  }

  int getChallengeQuizIndex({required String userId}) {
    return getProgress(userId).challengeQuizIndex;
  }

  void saveChallengeQuizIndex({required String userId, required int index}) {
    final StudentProgress p = getProgress(userId);
    p.challengeQuizIndex = index;
    _persist();
    notifyListeners();
  }

  bool isLessonBookmarked({required String userId, required String lessonId}) {
    return getProgress(userId).bookmarkedLessonIds.contains(lessonId);
  }

  bool toggleLessonBookmark({
    required String userId,
    required String lessonId,
  }) {
    final StudentProgress p = getProgress(userId);
    if (p.bookmarkedLessonIds.contains(lessonId)) {
      p.bookmarkedLessonIds.remove(lessonId);
      _persist();
      notifyListeners();
      return false;
    }
    p.bookmarkedLessonIds.add(lessonId);
    _persist();
    notifyListeners();
    return true;
  }

  List<LessonNote> getLessonNotes({
    required String userId,
    required String lessonId,
  }) {
    final StudentProgress p = getProgress(userId);
    final List<LessonNote> notes =
        p.notesByLessonId[lessonId] ?? <LessonNote>[];
    return List<LessonNote>.unmodifiable(notes);
  }

  LessonNote addLessonNote({
    required String userId,
    required String lessonId,
    required String highlightText,
    required String comment,
  }) {
    final StudentProgress p = getProgress(userId);
    final List<LessonNote> notes = p.notesByLessonId.putIfAbsent(
      lessonId,
      () => <LessonNote>[],
    );
    final LessonNote note = LessonNote(
      id: '${DateTime.now().microsecondsSinceEpoch}',
      lessonId: lessonId,
      highlightText: highlightText,
      comment: comment,
    );
    notes.insert(0, note);
    _persist();
    notifyListeners();
    return note;
  }

  void removeLessonNote({
    required String userId,
    required String lessonId,
    required String noteId,
  }) {
    final StudentProgress p = getProgress(userId);
    final List<LessonNote>? notes = p.notesByLessonId[lessonId];
    if (notes == null) return;
    notes.removeWhere((LessonNote n) => n.id == noteId);
    _persist();
    notifyListeners();
  }

  List<VideoTimestamp> getVideoTimestamps({
    required String userId,
    required String lessonId,
  }) {
    final StudentProgress p = getProgress(userId);
    final List<VideoTimestamp> items =
        p.timestampsByLessonId[lessonId] ?? <VideoTimestamp>[];
    return List<VideoTimestamp>.unmodifiable(items);
  }

  VideoTimestamp addVideoTimestamp({
    required String userId,
    required String lessonId,
    required int seconds,
    required String label,
  }) {
    final StudentProgress p = getProgress(userId);
    final List<VideoTimestamp> items = p.timestampsByLessonId.putIfAbsent(
      lessonId,
      () => <VideoTimestamp>[],
    );
    final VideoTimestamp ts = VideoTimestamp(
      id: '${DateTime.now().microsecondsSinceEpoch}',
      lessonId: lessonId,
      seconds: seconds,
      label: label,
    );
    items.insert(0, ts);
    _persist();
    notifyListeners();
    return ts;
  }

  void removeVideoTimestamp({
    required String userId,
    required String lessonId,
    required String timestampId,
  }) {
    final StudentProgress p = getProgress(userId);
    final List<VideoTimestamp>? items = p.timestampsByLessonId[lessonId];
    if (items == null) return;
    items.removeWhere((VideoTimestamp t) => t.id == timestampId);
    _persist();
    notifyListeners();
  }

  Future<void> _persist() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final Map<String, dynamic> payload = _progressByUserId.map(
      (String key, StudentProgress value) =>
          MapEntry<String, dynamic>(key, value.toJson()),
    );
    await prefs.setString(_storageKey, jsonEncode(payload));
  }
}
