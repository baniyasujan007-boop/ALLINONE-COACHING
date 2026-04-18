class CoursePricingItem {
  const CoursePricingItem({
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
}

class CourseOfferItem {
  const CourseOfferItem({
    this.title = '',
    this.pricing = const CoursePricingItem(),
    this.expiresAt,
  });

  final String title;
  final CoursePricingItem pricing;
  final DateTime? expiresAt;

  bool get isActive =>
      expiresAt != null &&
      expiresAt!.isAfter(DateTime.now()) &&
      pricing.lowest > 0;
}

class LessonItem {
  const LessonItem({
    required this.id,
    required this.title,
    required this.duration,
    required this.videoUrl,
    required this.description,
    required this.notesUrl,
  });

  final String id;
  final String title;
  final String duration;
  final String videoUrl;
  final String description;
  final String notesUrl;
}

class CourseItem {
  const CourseItem({
    required this.id,
    required this.title,
    required this.instructor,
    required this.thumbnail,
    required this.price,
    required this.pricing,
    required this.offer,
    required this.isLocked,
    required this.rating,
    required this.lessons,
    required this.progress,
    required this.description,
    required this.category,
    required this.quiz,
  });

  final String id;
  final String title;
  final String instructor;
  final String thumbnail;
  final double price;
  final CoursePricingItem pricing;
  final CourseOfferItem offer;
  final bool isLocked;
  final double rating;
  final List<LessonItem> lessons;
  final double progress;
  final String description;
  final String category;
  final List<QuizQuestion> quiz;
}

class QuizQuestion {
  const QuizQuestion({
    required this.question,
    required this.options,
    required this.answer,
  });

  final String question;
  final List<String> options;
  final String answer;
}
