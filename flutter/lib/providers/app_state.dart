import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_user.dart';
import '../models/course.dart' as api;
import '../models/course_model.dart';
import '../services/auth_service.dart';
import '../services/course_service.dart';

class AppState extends ChangeNotifier {
  static const String _darkModeKey = 'dark_mode';

  bool _darkMode = false;
  String _userName = 'Student';
  bool _authLoading = false;
  bool _coursesLoading = false;
  String? _authError;
  String? _coursesError;

  final List<CourseItem> _courses = <CourseItem>[];

  bool get darkMode => _darkMode;
  String get userName => _userName;
  bool get authLoading => _authLoading;
  bool get coursesLoading => _coursesLoading;
  String? get authError => _authError;
  String? get coursesError => _coursesError;
  List<CourseItem> get courses => List<CourseItem>.unmodifiable(_courses);
  AppUser? get currentUser => AuthService.instance.currentSession?.user;
  bool get isAdmin =>
      AuthService.instance.currentSession?.user.role == UserRole.admin;
  bool ownsCourse(String courseId) {
    final AppUser? user = currentUser;
    if (user == null) {
      return false;
    }
    if (user.role == UserRole.admin) {
      return true;
    }
    return user.enrolledCourses.any(
      (PurchasedCourse c) => c.id == courseId && c.hasActiveAccess,
    );
  }

  PaymentRecord? latestPaymentForCourse(String courseId) {
    final List<PaymentRecord> payments =
        currentUser?.paymentHistory ?? <PaymentRecord>[];
    PaymentRecord? latest;
    DateTime latestTime = DateTime.fromMillisecondsSinceEpoch(0);

    for (final PaymentRecord payment in payments) {
      if (payment.courseId != courseId) {
        continue;
      }
      final DateTime? paidAt = DateTime.tryParse(payment.paidAt);
      final DateTime sortTime =
          paidAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      if (latest == null || sortTime.isAfter(latestTime)) {
        latest = payment;
        latestTime = sortTime;
      }
    }

    return latest;
  }

  bool hasExpiredCourseAccess(String courseId) {
    final PaymentRecord? latest = latestPaymentForCourse(courseId);
    return latest != null && latest.isExpired && !ownsCourse(courseId);
  }

  List<QuizQuestion> get quiz {
    final List<QuizQuestion> all = <QuizQuestion>[];
    for (final CourseItem course in _courses) {
      all.addAll(course.quiz);
    }
    return all;
  }

  List<String> get categories {
    final List<String> derived =
        _courses
            .map((CourseItem course) => course.category)
            .where((String category) => category.trim().isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    return derived.isEmpty ? <String>['General'] : derived;
  }

  Future<void> restorePreferences() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    _darkMode = prefs.getBool(_darkModeKey) ?? false;
    notifyListeners();
  }

  Future<bool> login({required String email, required String password}) async {
    _authLoading = true;
    _authError = null;
    notifyListeners();

    final String? error = await AuthService.instance.login(
      email: email,
      password: password,
    );

    _authLoading = false;
    if (error != null) {
      _authError = error;
      notifyListeners();
      return false;
    }

    _userName = AuthService.instance.currentSession?.user.name ?? _userName;
    notifyListeners();
    return true;
  }

  Future<bool> loginWithGoogle() async {
    _authLoading = true;
    _authError = null;
    notifyListeners();

    final String? error = await AuthService.instance.loginWithGoogle();

    _authLoading = false;
    if (error != null) {
      _authError = error;
      notifyListeners();
      return false;
    }

    _userName = AuthService.instance.currentSession?.user.name ?? _userName;
    notifyListeners();
    return true;
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    _authLoading = true;
    _authError = null;
    notifyListeners();

    final String? error = await AuthService.instance.registerStudent(
      name: name,
      email: email,
      password: password,
    );

    _authLoading = false;
    _authError = error;
    notifyListeners();
    return error == null;
  }

  Future<bool> forgotPassword({
    required String email,
    required String newPassword,
  }) async {
    _authLoading = true;
    _authError = null;
    notifyListeners();

    final String? error = await AuthService.instance.forgotPassword(
      email: email,
      newPassword: newPassword,
    );

    _authLoading = false;
    _authError = error;
    notifyListeners();
    return error == null;
  }

  Future<bool> updateProfile({
    required String name,
    required String email,
    required String phone,
    required String address,
    required String profileImage,
  }) async {
    _authLoading = true;
    _authError = null;
    notifyListeners();

    final String? error = await AuthService.instance.updateProfile(
      name: name,
      email: email,
      phone: phone,
      address: address,
      profileImage: profileImage,
    );

    _authLoading = false;
    _authError = error;
    if (error == null) {
      _userName = AuthService.instance.currentSession?.user.name ?? _userName;
    }
    notifyListeners();
    return error == null;
  }

  Future<bool> refreshProfile() async {
    final String? error = await AuthService.instance.refreshProfile();
    _authError = error;
    if (error == null) {
      _userName = AuthService.instance.currentSession?.user.name ?? _userName;
    }
    notifyListeners();
    return error == null;
  }

  Future<bool> purchaseCourse(
    String courseId, {
    String paymentMethod = 'manual',
    String billingCycle = '',
  }) async {
    _authLoading = true;
    _authError = null;
    notifyListeners();

    final String? error = await CourseService.instance.purchaseCourse(
      courseId,
      paymentMethod: paymentMethod,
      billingCycle: billingCycle,
    );
    if (error == null) {
      final String? refreshError = await AuthService.instance.refreshProfile();
      _authError = refreshError;
      if (refreshError == null) {
        _userName = AuthService.instance.currentSession?.user.name ?? _userName;
      }
    } else {
      _authError = error;
    }

    _authLoading = false;
    notifyListeners();
    return _authError == null;
  }

  Future<void> logout() async {
    await AuthService.instance.logout();
    _userName = 'Student';
    _courses.clear();
    _authError = null;
    _coursesError = null;
    notifyListeners();
  }

  Future<void> toggleTheme(bool value) async {
    if (_darkMode == value) {
      return;
    }
    _darkMode = value;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_darkModeKey, value);
    notifyListeners();
  }

  CourseItem? courseById(String id) {
    try {
      return _courses.firstWhere((CourseItem c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> loadCourses({bool withDetails = true}) async {
    _coursesLoading = true;
    _coursesError = null;
    notifyListeners();

    try {
      if (withDetails) {
        await CourseService.instance.refreshAllCourseDetails();
      } else {
        await CourseService.instance.refreshCourses();
      }
      final List<api.Course> apiCourses = CourseService.instance.getCourses();
      _courses
        ..clear()
        ..addAll(apiCourses.map(_mapCourse));
    } catch (e) {
      _coursesError = e.toString();
    } finally {
      _coursesLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadCourseDetails(String courseId) async {
    try {
      await CourseService.instance.hydrateCourseDetails(courseId);
      final api.Course? course = CourseService.instance.getCourseById(courseId);
      if (course != null) {
        final int idx = _courses.indexWhere((CourseItem c) => c.id == courseId);
        if (idx >= 0) {
          _courses[idx] = _mapCourse(course);
        } else {
          _courses.add(_mapCourse(course));
        }
        notifyListeners();
      }
    } catch (e) {
      _coursesError = e.toString();
      notifyListeners();
    }
  }

  CourseItem _mapCourse(api.Course c) {
    final Map<String, String> notesByTitle = <String, String>{
      for (final api.StudyMaterial m in c.studyMaterials) m.title: m.pdfUrl,
    };

    final List<LessonItem> lessons = c.lessons.map((api.VideoLesson lesson) {
      String notes = '';
      for (final MapEntry<String, String> entry in notesByTitle.entries) {
        if (entry.key.toLowerCase().contains(lesson.title.toLowerCase())) {
          notes = entry.value;
          break;
        }
      }
      if (notes.isEmpty && c.studyMaterials.isNotEmpty) {
        notes = c.studyMaterials.first.pdfUrl;
      }

      return LessonItem(
        id: lesson.id,
        title: lesson.title,
        duration: '${lesson.durationMinutes} min',
        videoUrl: lesson.videoUrl.isEmpty
            ? 'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4'
            : lesson.videoUrl,
        description:
            'Lesson from ${c.title} by ${c.instructor.isEmpty ? 'Instructor' : c.instructor}.',
        notesUrl: notes,
      );
    }).toList();

    final List<QuizQuestion> quizQuestions = c.quizQuestions.map((
      api.QuizQuestion q,
    ) {
      final List<String> opts = q.options;
      final String answer = opts.isEmpty
          ? ''
          : opts[q.correctIndex.clamp(0, opts.length - 1)];
      return QuizQuestion(question: q.question, options: opts, answer: answer);
    }).toList();

    return CourseItem(
      id: c.id,
      title: c.title,
      instructor: c.instructor.isEmpty ? 'Instructor' : c.instructor,
      thumbnail: c.thumbnailUrl.isEmpty
          ? 'https://images.unsplash.com/photo-1519389950473-47ba0277781c?q=80&w=1200&auto=format&fit=crop'
          : c.thumbnailUrl,
      price: c.pricing.lowest > 0 ? c.pricing.lowest : c.price,
      pricing: CoursePricingItem(
        monthly: c.pricing.monthly,
        quarterly: c.pricing.quarterly,
        semiAnnual: c.pricing.semiAnnual,
        yearly: c.pricing.yearly,
      ),
      offer: CourseOfferItem(
        title: c.offer.title,
        pricing: CoursePricingItem(
          monthly: c.offer.pricing.monthly,
          quarterly: c.offer.pricing.quarterly,
          semiAnnual: c.offer.pricing.semiAnnual,
          yearly: c.offer.pricing.yearly,
        ),
        expiresAt: c.offer.expiresAt,
      ),
      isLocked: c.isLocked,
      rating: 4.8,
      lessons: lessons,
      progress: 0.0,
      description: c.description,
      category: _deriveCategory(c),
      quiz: quizQuestions,
    );
  }

  String _deriveCategory(api.Course course) {
    final String source =
        '${course.title} ${course.description} ${course.instructor}'
            .toLowerCase();

    if (_matchesAny(source, <String>[
      'flutter',
      'dart',
      'web',
      'app',
      'programming',
      'code',
      'developer',
      'software',
      'api',
      'backend',
      'frontend',
    ])) {
      return 'Development';
    }

    if (_matchesAny(source, <String>[
      'ui',
      'ux',
      'design',
      'figma',
      'graphic',
      'visual',
      'branding',
    ])) {
      return 'Design';
    }

    if (_matchesAny(source, <String>[
      'marketing',
      'seo',
      'content',
      'social media',
      'brand',
      'copywriting',
    ])) {
      return 'Marketing';
    }

    if (_matchesAny(source, <String>[
      'business',
      'startup',
      'sales',
      'finance',
      'management',
      'entrepreneur',
    ])) {
      return 'Business';
    }

    if (_matchesAny(source, <String>[
      'ai',
      'machine learning',
      'artificial intelligence',
      'prompt',
      'llm',
      'automation',
      'data science',
    ])) {
      return 'AI';
    }

    if (_matchesAny(source, <String>[
      'productivity',
      'time management',
      'focus',
      'study',
      'habit',
      'workflow',
    ])) {
      return 'Productivity';
    }

    return 'General';
  }

  bool _matchesAny(String source, List<String> keywords) {
    for (final String keyword in keywords) {
      if (source.contains(keyword)) {
        return true;
      }
    }
    return false;
  }
}
