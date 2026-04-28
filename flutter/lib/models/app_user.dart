import 'course.dart';
import 'promotion.dart';

enum UserRole { student, admin }

class PaymentRecord {
  const PaymentRecord({
    required this.courseId,
    required this.courseTitle,
    required this.amount,
    required this.originalAmount,
    required this.paymentMethod,
    required this.billingCycle,
    required this.status,
    required this.paidAt,
    this.accessExpiresAt,
    this.couponCode = '',
    this.couponDiscount = 0,
    this.referralCode = '',
    this.referralDiscount = 0,
    this.referrerRewardAmount = 0,
  });

  final String courseId;
  final String courseTitle;
  final double amount;
  final double originalAmount;
  final String paymentMethod;
  final String billingCycle;
  final String status;
  final String paidAt;
  final DateTime? accessExpiresAt;
  final String couponCode;
  final double couponDiscount;
  final String referralCode;
  final double referralDiscount;
  final double referrerRewardAmount;

  factory PaymentRecord.fromApi(Map<String, dynamic> json) {
    return PaymentRecord(
      courseId: (json['courseId'] ?? '').toString(),
      courseTitle: (json['courseTitle'] ?? '').toString(),
      amount: (json['amount'] is num) ? (json['amount'] as num).toDouble() : 0,
      originalAmount: (json['originalAmount'] is num)
          ? (json['originalAmount'] as num).toDouble()
          : ((json['amount'] is num) ? (json['amount'] as num).toDouble() : 0),
      paymentMethod: (json['paymentMethod'] ?? 'manual').toString(),
      billingCycle: (json['billingCycle'] ?? '').toString(),
      status: (json['status'] ?? 'success').toString(),
      paidAt: (json['paidAt'] ?? '').toString(),
      accessExpiresAt: (json['accessExpiresAt'] ?? '').toString().isEmpty
          ? null
          : DateTime.tryParse((json['accessExpiresAt'] ?? '').toString()),
      couponCode: (json['couponCode'] ?? '').toString(),
      couponDiscount: (json['couponDiscount'] is num)
          ? (json['couponDiscount'] as num).toDouble()
          : 0,
      referralCode: (json['referralCode'] ?? '').toString(),
      referralDiscount: (json['referralDiscount'] is num)
          ? (json['referralDiscount'] as num).toDouble()
          : 0,
      referrerRewardAmount: (json['referrerRewardAmount'] is num)
          ? (json['referrerRewardAmount'] as num).toDouble()
          : 0,
    );
  }

  bool get hasActiveAccess =>
      accessExpiresAt == null || accessExpiresAt!.isAfter(DateTime.now());

  bool get isExpired =>
      accessExpiresAt != null && !accessExpiresAt!.isAfter(DateTime.now());
}

class PurchasedCourse {
  const PurchasedCourse({
    required this.id,
    required this.title,
    required this.price,
    required this.pricing,
    required this.thumbnail,
    this.accessExpiresAt,
  });

  final String id;
  final String title;
  final double price;
  final CoursePricing pricing;
  final String thumbnail;
  final DateTime? accessExpiresAt;

  factory PurchasedCourse.fromApi(Map<String, dynamic> json) {
    return PurchasedCourse(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      price: (json['price'] is num) ? (json['price'] as num).toDouble() : 0,
      pricing: CoursePricing.fromApi(
        json['pricing'] as Map<String, dynamic>?,
        fallback: (json['price'] is num)
            ? (json['price'] as num).toDouble()
            : 0,
      ),
      thumbnail: (json['thumbnail'] ?? '').toString(),
      accessExpiresAt: (json['accessExpiresAt'] ?? '').toString().isEmpty
          ? null
          : DateTime.tryParse((json['accessExpiresAt'] ?? '').toString()),
    );
  }

  bool get hasActiveAccess =>
      accessExpiresAt == null || accessExpiresAt!.isAfter(DateTime.now());
}

class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.enrolledCourses = const <PurchasedCourse>[],
    this.paymentHistory = const <PaymentRecord>[],
    this.phone = '',
    this.address = '',
    this.profileImage = '',
    this.passwordHash = '',
    this.referralCode = '',
    this.referralSummary = const ReferralSummary(),
  });

  final String id;
  final String name;
  final String email;
  final String phone;
  final String address;
  final String profileImage;
  final String passwordHash;
  final String referralCode;
  final ReferralSummary referralSummary;
  final UserRole role;
  final List<PurchasedCourse> enrolledCourses;
  final List<PaymentRecord> paymentHistory;

  factory AppUser.fromApi(Map<String, dynamic> json) {
    final String roleRaw = (json['role'] ?? 'student').toString();
    final List<dynamic> rawCourses =
        (json['enrolledCourses'] as List?) ?? <dynamic>[];
    final List<dynamic> rawPayments =
        (json['paymentHistory'] as List?) ?? <dynamic>[];
    return AppUser(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      address: (json['address'] ?? '').toString(),
      profileImage: (json['profileImage'] ?? '').toString(),
      referralCode: (json['referralCode'] ?? '').toString(),
      referralSummary: ReferralSummary.fromApi(
        json['referralSummary'] as Map<String, dynamic>?,
      ),
      role: roleRaw == 'admin' ? UserRole.admin : UserRole.student,
      enrolledCourses: rawCourses
          .whereType<Map<String, dynamic>>()
          .map(PurchasedCourse.fromApi)
          .toList(),
      paymentHistory: rawPayments
          .whereType<Map<String, dynamic>>()
          .map(PaymentRecord.fromApi)
          .toList(),
    );
  }

  AppUser copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? address,
    String? profileImage,
    String? passwordHash,
    String? referralCode,
    ReferralSummary? referralSummary,
    UserRole? role,
    List<PurchasedCourse>? enrolledCourses,
    List<PaymentRecord>? paymentHistory,
  }) {
    return AppUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      profileImage: profileImage ?? this.profileImage,
      passwordHash: passwordHash ?? this.passwordHash,
      referralCode: referralCode ?? this.referralCode,
      referralSummary: referralSummary ?? this.referralSummary,
      role: role ?? this.role,
      enrolledCourses: enrolledCourses ?? this.enrolledCourses,
      paymentHistory: paymentHistory ?? this.paymentHistory,
    );
  }
}
