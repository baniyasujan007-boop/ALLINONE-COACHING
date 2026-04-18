class CoursePricing {
  const CoursePricing({
    this.monthly = 0,
    this.quarterly = 0,
    this.semiAnnual = 0,
    this.yearly = 0,
  });

  final double monthly;
  final double quarterly;
  final double semiAnnual;
  final double yearly;

  double get lowest {
    final List<double> values = <double>[
      monthly,
      quarterly,
      semiAnnual,
      yearly,
    ].where((double value) => value > 0).toList();
    if (values.isEmpty) {
      return 0;
    }
    values.sort();
    return values.first;
  }

  factory CoursePricing.fromApi(Map<String, dynamic>? json, {double fallback = 0}) {
    final CoursePricing pricing = CoursePricing(
      monthly: (json?['monthly'] is num)
          ? (json!['monthly'] as num).toDouble()
          : 0,
      quarterly: (json?['quarterly'] is num)
          ? (json!['quarterly'] as num).toDouble()
          : 0,
      semiAnnual: (json?['semiAnnual'] is num)
          ? (json!['semiAnnual'] as num).toDouble()
          : 0,
      yearly: (json?['yearly'] is num)
          ? (json!['yearly'] as num).toDouble()
          : 0,
    );
    if (pricing.lowest > 0 || fallback <= 0) {
      return pricing;
    }
    return CoursePricing(
      monthly: fallback,
      quarterly: fallback * 2.7,
      semiAnnual: fallback * 5,
      yearly: fallback * 9,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'monthly': monthly,
      'quarterly': quarterly,
      'semiAnnual': semiAnnual,
      'yearly': yearly,
    };
  }
}

class CourseOffer {
  const CourseOffer({
    this.title = '',
    this.pricing = const CoursePricing(),
    this.expiresAt,
  });

  final String title;
  final CoursePricing pricing;
  final DateTime? expiresAt;

  bool get isActive =>
      expiresAt != null &&
      expiresAt!.isAfter(DateTime.now()) &&
      pricing.lowest > 0;

  factory CourseOffer.fromApi(Map<String, dynamic>? json) {
    final String rawDate = (json?['expiresAt'] ?? '').toString();
    final DateTime? expiresAt = rawDate.isEmpty ? null : DateTime.tryParse(rawDate);
    return CourseOffer(
      title: (json?['title'] ?? '').toString(),
      pricing: CoursePricing.fromApi(json?['pricing'] as Map<String, dynamic>?),
      expiresAt: expiresAt,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'title': title,
      'pricing': pricing.toJson(),
      'expiresAt': expiresAt?.toIso8601String(),
    };
  }
}

class VideoLesson {
  const VideoLesson({
    required this.id,
    required this.title,
    required this.videoUrl,
    required this.durationMinutes,
  });

  final String id;
  final String title;
  final String videoUrl;
  final int durationMinutes;
}

class StudyMaterial {
  const StudyMaterial({
    required this.id,
    required this.title,
    required this.pdfUrl,
  });

  final String id;
  final String title;
  final String pdfUrl;
}

class QuizQuestion {
  const QuizQuestion({
    required this.id,
    required this.quizId,
    required this.questionIndex,
    required this.question,
    required this.options,
    required this.correctIndex,
  });

  final String id;
  final String quizId;
  final int questionIndex;
  final String question;
  final List<String> options;
  final int correctIndex;
}

class Course {
  const Course({
    required this.id,
    required this.title,
    required this.description,
    required this.thumbnailUrl,
    required this.lessons,
    required this.studyMaterials,
    required this.quizQuestions,
    this.instructor = '',
    this.price = 0,
    this.pricing = const CoursePricing(),
    this.offer = const CourseOffer(),
    this.isLocked = false,
  });

  final String id;
  final String title;
  final String description;
  final String thumbnailUrl;
  final String instructor;
  final double price;
  final CoursePricing pricing;
  final CourseOffer offer;
  final bool isLocked;
  final List<VideoLesson> lessons;
  final List<StudyMaterial> studyMaterials;
  final List<QuizQuestion> quizQuestions;

  Course copyWith({
    String? id,
    String? title,
    String? description,
    String? thumbnailUrl,
    String? instructor,
    double? price,
    CoursePricing? pricing,
    CourseOffer? offer,
    bool? isLocked,
    List<VideoLesson>? lessons,
    List<StudyMaterial>? studyMaterials,
    List<QuizQuestion>? quizQuestions,
  }) {
    return Course(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      instructor: instructor ?? this.instructor,
      price: price ?? this.price,
      pricing: pricing ?? this.pricing,
      offer: offer ?? this.offer,
      isLocked: isLocked ?? this.isLocked,
      lessons: lessons ?? this.lessons,
      studyMaterials: studyMaterials ?? this.studyMaterials,
      quizQuestions: quizQuestions ?? this.quizQuestions,
    );
  }
}
