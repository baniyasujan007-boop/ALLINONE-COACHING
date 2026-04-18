class StudentProgress {
  StudentProgress({
    required this.userId,
    Set<String>? completedLessonIds,
    Map<String, int>? quizScoresByCourseId,
    Map<String, Map<String, int>>? quizAnswersByCourseId,
    Map<String, int>? challengeQuizAnswers,
    int? challengeQuizIndex,
    Set<String>? bookmarkedLessonIds,
    Map<String, List<LessonNote>>? notesByLessonId,
    Map<String, List<VideoTimestamp>>? timestampsByLessonId,
  }) : completedLessonIds = completedLessonIds ?? <String>{},
       quizScoresByCourseId = quizScoresByCourseId ?? <String, int>{},
       quizAnswersByCourseId =
           quizAnswersByCourseId ?? <String, Map<String, int>>{},
       challengeQuizAnswers = challengeQuizAnswers ?? <String, int>{},
       challengeQuizIndex = challengeQuizIndex ?? 0,
       bookmarkedLessonIds = bookmarkedLessonIds ?? <String>{},
       notesByLessonId = notesByLessonId ?? <String, List<LessonNote>>{},
       timestampsByLessonId =
           timestampsByLessonId ?? <String, List<VideoTimestamp>>{};

  final String userId;
  final Set<String> completedLessonIds;
  final Map<String, int> quizScoresByCourseId;
  final Map<String, Map<String, int>> quizAnswersByCourseId;
  final Map<String, int> challengeQuizAnswers;
  int challengeQuizIndex;
  final Set<String> bookmarkedLessonIds;
  final Map<String, List<LessonNote>> notesByLessonId;
  final Map<String, List<VideoTimestamp>> timestampsByLessonId;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'userId': userId,
      'completedLessonIds': completedLessonIds.toList(),
      'quizScoresByCourseId': quizScoresByCourseId,
      'quizAnswersByCourseId': quizAnswersByCourseId.map(
        (String key, Map<String, int> value) =>
            MapEntry<String, dynamic>(key, value),
      ),
      'challengeQuizAnswers': challengeQuizAnswers,
      'challengeQuizIndex': challengeQuizIndex,
      'bookmarkedLessonIds': bookmarkedLessonIds.toList(),
      'notesByLessonId': notesByLessonId.map(
        (String key, List<LessonNote> value) => MapEntry<String, dynamic>(
          key,
          value.map((LessonNote note) => note.toJson()).toList(),
        ),
      ),
      'timestampsByLessonId': timestampsByLessonId.map(
        (String key, List<VideoTimestamp> value) => MapEntry<String, dynamic>(
          key,
          value.map((VideoTimestamp item) => item.toJson()).toList(),
        ),
      ),
    };
  }

  factory StudentProgress.fromJson(Map<String, dynamic> json) {
    return StudentProgress(
      userId: (json['userId'] ?? '').toString(),
      completedLessonIds: ((json['completedLessonIds'] as List?) ?? <dynamic>[])
          .map((dynamic item) => item.toString())
          .toSet(),
      quizScoresByCourseId: _intMap(json['quizScoresByCourseId']),
      quizAnswersByCourseId: _nestedIntMap(json['quizAnswersByCourseId']),
      challengeQuizAnswers: _intMap(json['challengeQuizAnswers']),
      challengeQuizIndex: (json['challengeQuizIndex'] is num)
          ? (json['challengeQuizIndex'] as num).toInt()
          : 0,
      bookmarkedLessonIds:
          ((json['bookmarkedLessonIds'] as List?) ?? <dynamic>[])
              .map((dynamic item) => item.toString())
              .toSet(),
      notesByLessonId: _notesMap(json['notesByLessonId']),
      timestampsByLessonId: _timestampsMap(json['timestampsByLessonId']),
    );
  }

  static Map<String, int> _intMap(dynamic raw) {
    if (raw is! Map) {
      return <String, int>{};
    }
    final Map<String, int> result = <String, int>{};
    raw.forEach((dynamic key, dynamic value) {
      if (value is num) {
        result[key.toString()] = value.toInt();
      }
    });
    return result;
  }

  static Map<String, Map<String, int>> _nestedIntMap(dynamic raw) {
    if (raw is! Map) {
      return <String, Map<String, int>>{};
    }
    final Map<String, Map<String, int>> result = <String, Map<String, int>>{};
    raw.forEach((dynamic key, dynamic value) {
      result[key.toString()] = _intMap(value);
    });
    return result;
  }

  static Map<String, List<LessonNote>> _notesMap(dynamic raw) {
    if (raw is! Map) {
      return <String, List<LessonNote>>{};
    }
    final Map<String, List<LessonNote>> result = <String, List<LessonNote>>{};
    raw.forEach((dynamic key, dynamic value) {
      final List<dynamic> items = value is List ? value : <dynamic>[];
      result[key.toString()] = items
          .whereType<Map<String, dynamic>>()
          .map(LessonNote.fromJson)
          .toList();
    });
    return result;
  }

  static Map<String, List<VideoTimestamp>> _timestampsMap(dynamic raw) {
    if (raw is! Map) {
      return <String, List<VideoTimestamp>>{};
    }
    final Map<String, List<VideoTimestamp>> result =
        <String, List<VideoTimestamp>>{};
    raw.forEach((dynamic key, dynamic value) {
      final List<dynamic> items = value is List ? value : <dynamic>[];
      result[key.toString()] = items
          .whereType<Map<String, dynamic>>()
          .map(VideoTimestamp.fromJson)
          .toList();
    });
    return result;
  }
}

class LessonNote {
  LessonNote({
    required this.id,
    required this.lessonId,
    required this.highlightText,
    required this.comment,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final String id;
  final String lessonId;
  final String highlightText;
  final String comment;
  final DateTime createdAt;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'lessonId': lessonId,
      'highlightText': highlightText,
      'comment': comment,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory LessonNote.fromJson(Map<String, dynamic> json) {
    return LessonNote(
      id: (json['id'] ?? '').toString(),
      lessonId: (json['lessonId'] ?? '').toString(),
      highlightText: (json['highlightText'] ?? '').toString(),
      comment: (json['comment'] ?? '').toString(),
      createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()),
    );
  }
}

class VideoTimestamp {
  VideoTimestamp({
    required this.id,
    required this.lessonId,
    required this.seconds,
    required this.label,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final String id;
  final String lessonId;
  final int seconds;
  final String label;
  final DateTime createdAt;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'lessonId': lessonId,
      'seconds': seconds,
      'label': label,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory VideoTimestamp.fromJson(Map<String, dynamic> json) {
    return VideoTimestamp(
      id: (json['id'] ?? '').toString(),
      lessonId: (json['lessonId'] ?? '').toString(),
      seconds: (json['seconds'] is num) ? (json['seconds'] as num).toInt() : 0,
      label: (json['label'] ?? '').toString(),
      createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()),
    );
  }
}
