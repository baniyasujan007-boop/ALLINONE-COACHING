import 'dart:typed_data';

import '../data/quiz_seed_data.dart';
import '../models/course.dart';
import 'api_client.dart';

class CourseService {
  CourseService._();
  static final CourseService instance = CourseService._();

  final List<Course> _courses = <Course>[];

  List<Course> getCourses() => List<Course>.unmodifiable(_courses);

  Course? getCourseById(String courseId) {
    try {
      return _courses.firstWhere((Course c) => c.id == courseId);
    } catch (_) {
      return null;
    }
  }

  Future<void> refreshCourses() async {
    final dynamic json = await ApiClient.instance.get('/courses');
    if (json is! List) {
      throw ApiException('Invalid courses response');
    }
    _courses
      ..clear()
      ..addAll(json.whereType<Map<String, dynamic>>().map(_courseFromApi));
  }

  Future<void> hydrateCourseDetails(String courseId) async {
    final int index = _courses.indexWhere((Course c) => c.id == courseId);
    if (index == -1) {
      return;
    }

    final dynamic lessonsJson = await ApiClient.instance.get(
      '/lessons/$courseId',
    );
    final dynamic quizJson = await ApiClient.instance.get('/quiz/$courseId');

    final List<VideoLesson> lessons = <VideoLesson>[];
    final List<StudyMaterial> materials = <StudyMaterial>[];

    if (lessonsJson is List) {
      for (final dynamic item in lessonsJson) {
        if (item is! Map<String, dynamic>) continue;
        final String lessonId = (item['_id'] ?? '').toString();
        final String title = (item['title'] ?? '').toString();
        final String videoUrl = (item['videoUrl'] ?? '').toString();
        final int duration = (item['duration'] is num)
            ? (item['duration'] as num).round()
            : 0;
        lessons.add(
          VideoLesson(
            id: lessonId,
            title: title,
            videoUrl: videoUrl,
            durationMinutes: duration,
          ),
        );

        final String notesPdf = (item['notesPdf'] ?? '').toString();
        if (notesPdf.isNotEmpty) {
          final String notesTitle = (item['notesTitle'] ?? '').toString();
          materials.add(
            StudyMaterial(
              id: 'pdf_$lessonId',
              title: notesTitle.isNotEmpty ? notesTitle : '$title Notes',
              pdfUrl: notesPdf,
            ),
          );
        }
      }
    }

    final List<QuizQuestion> allQuestions = <QuizQuestion>[];
    if (quizJson is List) {
      for (final dynamic quiz in quizJson) {
        if (quiz is! Map<String, dynamic>) continue;
        final List<dynamic> questions =
            (quiz['questions'] as List?) ?? <dynamic>[];
        final List<dynamic> options = (quiz['options'] as List?) ?? <dynamic>[];
        final List<dynamic> correctAnswers =
            (quiz['correctAnswer'] as List?) ?? <dynamic>[];

        for (int i = 0; i < questions.length; i++) {
          final List<String> opts = i < options.length && options[i] is List
              ? (options[i] as List).map((dynamic e) => e.toString()).toList()
              : <String>[];
          final String answer = i < correctAnswers.length
              ? correctAnswers[i].toString()
              : '';
          int correctIndex = 0;
          if (opts.isNotEmpty) {
            final int idx = opts.indexOf(answer);
            correctIndex = idx >= 0 ? idx : 0;
          }

          allQuestions.add(
            QuizQuestion(
              id: '${quiz['_id']}_$i',
              quizId: (quiz['_id'] ?? '').toString(),
              questionIndex: i,
              question: questions[i].toString(),
              options: opts,
              correctIndex: correctIndex,
            ),
          );
        }
      }
    }

    if (allQuestions.length < 50) {
      final Set<String> existingQuestions = allQuestions
          .map((QuizQuestion q) => q.question.trim().toLowerCase())
          .toSet();
      final List<QuizQuestion> fallbackQuestions = buildSeedQuizQuestions(
        courseId: courseId,
        topic: _courses[index].title,
      );
      for (final QuizQuestion question in fallbackQuestions) {
        if (allQuestions.length >= 50) {
          break;
        }
        if (existingQuestions.add(question.question.trim().toLowerCase())) {
          allQuestions.add(
            QuizQuestion(
              id: '${question.id}_fallback_${allQuestions.length}',
              quizId: question.quizId,
              questionIndex: allQuestions.length,
              question: question.question,
              options: question.options,
              correctIndex: question.correctIndex,
            ),
          );
        }
      }
    }

    _courses[index] = _courses[index].copyWith(
      lessons: lessons,
      studyMaterials: materials,
      quizQuestions: allQuestions,
    );
  }

  Future<void> refreshAllCourseDetails() async {
    await refreshCourses();
    for (final Course c in List<Course>.from(_courses)) {
      await hydrateCourseDetails(c.id);
    }
  }

  Future<void> addCourse({
    required String title,
    required String description,
    required String thumbnailUrl,
    required double price,
    required CoursePricing pricing,
    required CourseOffer offer,
    required bool isLocked,
  }) async {
    await ApiClient.instance.post('/courses', <String, dynamic>{
      'title': title,
      'description': description,
      'thumbnail': thumbnailUrl,
      'price': price,
      'pricing': pricing.toJson(),
      'offer': offer.toJson(),
      'isLocked': isLocked,
    }, auth: true);
    await refreshCourses();
  }

  Future<String> uploadCourseFile({
    required Uint8List bytes,
    required String filename,
  }) async {
    final dynamic json = await ApiClient.instance.uploadFile(
      '/upload/file',
      bytes: bytes,
      filename: filename,
      auth: true,
    );
    if (json is! Map<String, dynamic>) {
      throw ApiException('Invalid file upload response');
    }
    final String url = (json['url'] ?? '').toString();
    if (url.isEmpty) {
      throw ApiException('File upload failed');
    }
    return url;
  }

  Future<String> uploadCourseThumbnail({
    required Uint8List bytes,
    required String filename,
  }) async {
    final dynamic json = await ApiClient.instance.uploadFile(
      '/upload/thumbnail',
      bytes: bytes,
      filename: filename,
      auth: true,
    );
    if (json is! Map<String, dynamic>) {
      throw ApiException('Invalid thumbnail upload response');
    }
    final String url = (json['url'] ?? '').toString();
    if (url.isEmpty) {
      throw ApiException('Thumbnail upload failed');
    }
    return url;
  }

  Future<void> updateCourse({
    required String courseId,
    required String title,
    required String description,
    required String thumbnailUrl,
    required double price,
    required CoursePricing pricing,
    required CourseOffer offer,
    required bool isLocked,
  }) async {
    await ApiClient.instance.put('/courses/$courseId', <String, dynamic>{
      'title': title,
      'description': description,
      'thumbnail': thumbnailUrl,
      'price': price,
      'pricing': pricing.toJson(),
      'offer': offer.toJson(),
      'isLocked': isLocked,
    }, auth: true);
    await refreshCourses();
  }

  Future<String?> purchaseCourse(
    String courseId, {
    String paymentMethod = 'manual',
    String billingCycle = '',
  }) async {
    try {
      await ApiClient.instance.post(
        '/courses/$courseId/purchase',
        <String, dynamic>{
          'paymentMethod': paymentMethod,
          'billingCycle': billingCycle,
        },
        auth: true,
      );
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'Unable to complete purchase right now.';
    }
  }

  Future<void> deleteCourse(String courseId) async {
    await ApiClient.instance.delete('/courses/$courseId', auth: true);
    _courses.removeWhere((Course c) => c.id == courseId);
  }

  Future<void> addLesson({
    required String courseId,
    required String title,
    required String videoUrl,
    required int durationMinutes,
  }) async {
    await ApiClient.instance.post('/lessons', <String, dynamic>{
      'courseId': courseId,
      'title': title,
      'videoUrl': videoUrl,
      'duration': durationMinutes,
    }, auth: true);
    await hydrateCourseDetails(courseId);
  }

  Future<void> addStudyMaterial({
    required String courseId,
    required String title,
    required String pdfUrl,
  }) async {
    // A lesson can represent notes-only content in backend.
    await ApiClient.instance.post('/lessons', <String, dynamic>{
      'courseId': courseId,
      'title': title,
      'notesTitle': title,
      'notesPdf': pdfUrl,
      'duration': 0,
    }, auth: true);
    await hydrateCourseDetails(courseId);
  }

  Future<void> updateLesson({
    required String courseId,
    required String lessonId,
    required String title,
    required String videoUrl,
    required int durationMinutes,
  }) async {
    await ApiClient.instance.put('/lessons/item/$lessonId', <String, dynamic>{
      'title': title,
      'videoUrl': videoUrl,
      'duration': durationMinutes,
    }, auth: true);
    await hydrateCourseDetails(courseId);
  }

  Future<void> deleteLesson({
    required String courseId,
    required String lessonId,
  }) async {
    await ApiClient.instance.delete('/lessons/item/$lessonId', auth: true);
    await hydrateCourseDetails(courseId);
  }

  String _lessonIdFromMaterialId(String materialId) {
    if (materialId.startsWith('pdf_')) {
      return materialId.substring(4);
    }
    return materialId;
  }

  Future<void> updateStudyMaterial({
    required String courseId,
    required String materialId,
    required String title,
    required String fileUrl,
  }) async {
    final String lessonId = _lessonIdFromMaterialId(materialId);
    await ApiClient.instance.put('/lessons/item/$lessonId', <String, dynamic>{
      'notesTitle': title,
      'notesPdf': fileUrl,
    }, auth: true);
    await hydrateCourseDetails(courseId);
  }

  Future<void> deleteStudyMaterial({
    required String courseId,
    required String materialId,
  }) async {
    final String lessonId = _lessonIdFromMaterialId(materialId);
    final Course? course = getCourseById(courseId);
    VideoLesson? lesson;
    if (course != null) {
      for (final VideoLesson item in course.lessons) {
        if (item.id == lessonId) {
          lesson = item;
          break;
        }
      }
    }

    if (lesson != null && lesson.videoUrl.trim().isNotEmpty) {
      await ApiClient.instance.put('/lessons/item/$lessonId', <String, dynamic>{
        'notesPdf': '',
        'notesTitle': '',
      }, auth: true);
    } else {
      await ApiClient.instance.delete('/lessons/item/$lessonId', auth: true);
    }
    await hydrateCourseDetails(courseId);
  }

  Future<void> addQuizQuestion({
    required String courseId,
    required String question,
    required List<String> options,
    required int correctIndex,
  }) async {
    final String correct = options.isNotEmpty
        ? options[correctIndex.clamp(0, options.length - 1)]
        : '';
    await ApiClient.instance.post('/quiz', <String, dynamic>{
      'courseId': courseId,
      'questions': <String>[question],
      'options': <List<String>>[options],
      'correctAnswer': <String>[correct],
    }, auth: true);
    await hydrateCourseDetails(courseId);
  }

  Future<void> updateQuizQuestion({
    required String courseId,
    required String quizId,
    required int questionIndex,
    required String question,
    required List<String> options,
    required int correctIndex,
  }) async {
    await ApiClient.instance.put(
      '/quiz/$quizId/questions/$questionIndex',
      <String, dynamic>{
        'question': question,
        'options': options,
        'correctIndex': correctIndex,
      },
      auth: true,
    );
    await hydrateCourseDetails(courseId);
  }

  Future<void> deleteQuizQuestion({
    required String courseId,
    required String quizId,
    required int questionIndex,
  }) async {
    await ApiClient.instance.delete(
      '/quiz/$quizId/questions/$questionIndex',
      auth: true,
    );
    await hydrateCourseDetails(courseId);
  }

  Course _courseFromApi(Map<String, dynamic> json) {
    return Course(
      id: (json['_id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      thumbnailUrl: (json['thumbnail'] ?? '').toString(),
      instructor: (json['instructor'] ?? '').toString(),
      price: (json['price'] is num) ? (json['price'] as num).toDouble() : 0,
      pricing: CoursePricing.fromApi(
        json['pricing'] as Map<String, dynamic>?,
        fallback: (json['price'] is num) ? (json['price'] as num).toDouble() : 0,
      ),
      offer: CourseOffer.fromApi(json['offer'] as Map<String, dynamic>?),
      isLocked: json['isLocked'] != false,
      lessons: const <VideoLesson>[],
      studyMaterials: const <StudyMaterial>[],
      quizQuestions: const <QuizQuestion>[],
    );
  }
}
