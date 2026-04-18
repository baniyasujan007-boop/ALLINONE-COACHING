class AdminPurchasedPackage {
  const AdminPurchasedPackage({
    required this.id,
    required this.title,
    required this.price,
    required this.thumbnail,
    this.accessExpiresAt,
  });

  final String id;
  final String title;
  final double price;
  final String thumbnail;
  final DateTime? accessExpiresAt;

  factory AdminPurchasedPackage.fromApi(Map<String, dynamic> json) {
    return AdminPurchasedPackage(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      price: (json['price'] is num) ? (json['price'] as num).toDouble() : 0,
      thumbnail: (json['thumbnail'] ?? '').toString(),
      accessExpiresAt: (json['accessExpiresAt'] ?? '').toString().isEmpty
          ? null
          : DateTime.tryParse((json['accessExpiresAt'] ?? '').toString()),
    );
  }
}

class AdminPaymentRecord {
  const AdminPaymentRecord({
    required this.courseId,
    required this.courseTitle,
    required this.amount,
    required this.paymentMethod,
    required this.billingCycle,
    required this.status,
    required this.paidAt,
    this.accessExpiresAt,
  });

  final String courseId;
  final String courseTitle;
  final double amount;
  final String paymentMethod;
  final String billingCycle;
  final String status;
  final String paidAt;
  final DateTime? accessExpiresAt;

  factory AdminPaymentRecord.fromApi(Map<String, dynamic> json) {
    return AdminPaymentRecord(
      courseId: (json['courseId'] ?? '').toString(),
      courseTitle: (json['courseTitle'] ?? '').toString(),
      amount: (json['amount'] is num) ? (json['amount'] as num).toDouble() : 0,
      paymentMethod: (json['paymentMethod'] ?? 'manual').toString(),
      billingCycle: (json['billingCycle'] ?? '').toString(),
      status: (json['status'] ?? 'success').toString(),
      paidAt: (json['paidAt'] ?? '').toString(),
      accessExpiresAt: (json['accessExpiresAt'] ?? '').toString().isEmpty
          ? null
          : DateTime.tryParse((json['accessExpiresAt'] ?? '').toString()),
    );
  }
}

class AdminUser {
  const AdminUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.phone,
    required this.address,
    required this.profileImage,
    required this.purchasedPackages,
    required this.paymentHistory,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String email;
  final String role;
  final String phone;
  final String address;
  final String profileImage;
  final List<AdminPurchasedPackage> purchasedPackages;
  final List<AdminPaymentRecord> paymentHistory;
  final String createdAt;

  factory AdminUser.fromApi(Map<String, dynamic> json) {
    final List<dynamic> raw = (json['enrolledCourses'] as List?) ?? <dynamic>[];
    final List<dynamic> rawPayments =
        (json['paymentHistory'] as List?) ?? <dynamic>[];
    return AdminUser(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      role: (json['role'] ?? 'student').toString(),
      phone: (json['phone'] ?? '').toString(),
      address: (json['address'] ?? '').toString(),
      profileImage: (json['profileImage'] ?? '').toString(),
      purchasedPackages: raw
          .whereType<Map<String, dynamic>>()
          .map(AdminPurchasedPackage.fromApi)
          .toList(),
      paymentHistory: rawPayments
          .whereType<Map<String, dynamic>>()
          .map(AdminPaymentRecord.fromApi)
          .toList(),
      createdAt: (json['createdAt'] ?? '').toString(),
    );
  }

  double get totalSpent {
    double total = 0;
    for (final AdminPaymentRecord payment in paymentHistory) {
      total += payment.amount;
    }
    return total;
  }
}
