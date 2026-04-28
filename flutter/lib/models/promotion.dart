class ReferralSummary {
  const ReferralSummary({
    this.code = '',
    this.successfulReferrals = 0,
    this.earnedRewards = 0,
    this.hasUsedReferral = false,
  });

  final String code;
  final int successfulReferrals;
  final double earnedRewards;
  final bool hasUsedReferral;

  factory ReferralSummary.fromApi(Map<String, dynamic>? json) {
    return ReferralSummary(
      code: (json?['code'] ?? '').toString(),
      successfulReferrals: (json?['successfulReferrals'] is num)
          ? (json!['successfulReferrals'] as num).toInt()
          : 0,
      earnedRewards: (json?['earnedRewards'] is num)
          ? (json!['earnedRewards'] as num).toDouble()
          : 0,
      hasUsedReferral: json?['hasUsedReferral'] == true,
    );
  }
}

class CheckoutPreview {
  const CheckoutPreview({
    required this.originalAmount,
    required this.finalAmount,
    this.couponCode = '',
    this.couponDiscount = 0,
    this.referralCode = '',
    this.referralDiscount = 0,
    this.referrerRewardAmount = 0,
    this.referralOwnerName = '',
    this.messages = const <String>[],
  });

  final double originalAmount;
  final double finalAmount;
  final String couponCode;
  final double couponDiscount;
  final String referralCode;
  final double referralDiscount;
  final double referrerRewardAmount;
  final String referralOwnerName;
  final List<String> messages;

  factory CheckoutPreview.fromApi(Map<String, dynamic> json) {
    final List<dynamic> rawMessages = (json['messages'] as List?) ?? <dynamic>[];
    return CheckoutPreview(
      originalAmount: (json['originalAmount'] is num)
          ? (json['originalAmount'] as num).toDouble()
          : 0,
      finalAmount: (json['finalAmount'] is num)
          ? (json['finalAmount'] as num).toDouble()
          : 0,
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
      referralOwnerName: (json['referralOwnerName'] ?? '').toString(),
      messages: rawMessages.map((dynamic item) => item.toString()).toList(),
    );
  }
}

class CouponAdminItem {
  const CouponAdminItem({
    required this.id,
    required this.code,
    required this.type,
    required this.value,
    required this.maxRedemptions,
    required this.perUserLimit,
    required this.minOrderAmount,
    required this.usageCount,
    required this.isActive,
    this.expiresAt,
  });

  final String id;
  final String code;
  final String type;
  final double value;
  final int maxRedemptions;
  final int perUserLimit;
  final double minOrderAmount;
  final int usageCount;
  final bool isActive;
  final DateTime? expiresAt;

  factory CouponAdminItem.fromApi(Map<String, dynamic> json) {
    return CouponAdminItem(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      code: (json['code'] ?? '').toString(),
      type: (json['type'] ?? 'flat').toString(),
      value: (json['value'] is num) ? (json['value'] as num).toDouble() : 0,
      maxRedemptions: (json['maxRedemptions'] is num)
          ? (json['maxRedemptions'] as num).toInt()
          : 0,
      perUserLimit: (json['perUserLimit'] is num)
          ? (json['perUserLimit'] as num).toInt()
          : 0,
      minOrderAmount: (json['minOrderAmount'] is num)
          ? (json['minOrderAmount'] as num).toDouble()
          : 0,
      usageCount: (json['usageCount'] is num)
          ? (json['usageCount'] as num).toInt()
          : 0,
      isActive: json['isActive'] != false,
      expiresAt: (json['expiresAt'] ?? '').toString().isEmpty
          ? null
          : DateTime.tryParse((json['expiresAt'] ?? '').toString()),
    );
  }
}

class ReferralSettings {
  const ReferralSettings({
    this.enabled = true,
    this.refereeRewardType = 'flat',
    this.refereeRewardValue = 0,
    this.referrerRewardType = 'flat',
    this.referrerRewardValue = 0,
    this.minOrderAmount = 0,
    this.firstPurchaseOnly = true,
    this.maxSuccessfulReferralsPerUser = 0,
    this.maxUsesPerCode = 0,
    this.maxRewardsPerIp = 0,
  });

  final bool enabled;
  final String refereeRewardType;
  final double refereeRewardValue;
  final String referrerRewardType;
  final double referrerRewardValue;
  final double minOrderAmount;
  final bool firstPurchaseOnly;
  final int maxSuccessfulReferralsPerUser;
  final int maxUsesPerCode;
  final int maxRewardsPerIp;

  factory ReferralSettings.fromApi(Map<String, dynamic>? json) {
    return ReferralSettings(
      enabled: json?['enabled'] != false,
      refereeRewardType: (json?['refereeRewardType'] ?? 'flat').toString(),
      refereeRewardValue: (json?['refereeRewardValue'] is num)
          ? (json!['refereeRewardValue'] as num).toDouble()
          : 0,
      referrerRewardType: (json?['referrerRewardType'] ?? 'flat').toString(),
      referrerRewardValue: (json?['referrerRewardValue'] is num)
          ? (json!['referrerRewardValue'] as num).toDouble()
          : 0,
      minOrderAmount: (json?['minOrderAmount'] is num)
          ? (json!['minOrderAmount'] as num).toDouble()
          : 0,
      firstPurchaseOnly: json?['firstPurchaseOnly'] != false,
      maxSuccessfulReferralsPerUser:
          (json?['maxSuccessfulReferralsPerUser'] is num)
              ? (json!['maxSuccessfulReferralsPerUser'] as num).toInt()
              : 0,
      maxUsesPerCode: (json?['maxUsesPerCode'] is num)
          ? (json!['maxUsesPerCode'] as num).toInt()
          : 0,
      maxRewardsPerIp: (json?['maxRewardsPerIp'] is num)
          ? (json!['maxRewardsPerIp'] as num).toInt()
          : 0,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'enabled': enabled,
      'refereeRewardType': refereeRewardType,
      'refereeRewardValue': refereeRewardValue,
      'referrerRewardType': referrerRewardType,
      'referrerRewardValue': referrerRewardValue,
      'minOrderAmount': minOrderAmount,
      'firstPurchaseOnly': firstPurchaseOnly,
      'maxSuccessfulReferralsPerUser': maxSuccessfulReferralsPerUser,
      'maxUsesPerCode': maxUsesPerCode,
      'maxRewardsPerIp': maxRewardsPerIp,
    };
  }
}

class ReferralEventAdminItem {
  const ReferralEventAdminItem({
    required this.id,
    required this.referralCode,
    required this.courseTitle,
    required this.billingCycle,
    required this.originalAmount,
    required this.finalAmount,
    required this.refereeDiscountAmount,
    required this.referrerRewardAmount,
    required this.status,
    required this.referrerName,
    required this.referrerEmail,
    required this.referredUserName,
    required this.referredUserEmail,
    required this.createdAt,
  });

  final String id;
  final String referralCode;
  final String courseTitle;
  final String billingCycle;
  final double originalAmount;
  final double finalAmount;
  final double refereeDiscountAmount;
  final double referrerRewardAmount;
  final String status;
  final String referrerName;
  final String referrerEmail;
  final String referredUserName;
  final String referredUserEmail;
  final DateTime? createdAt;

  factory ReferralEventAdminItem.fromApi(Map<String, dynamic> json) {
    final Map<String, dynamic>? rawReferrer =
        json['referrer'] as Map<String, dynamic>?;
    final Map<String, dynamic>? rawReferredUser =
        json['referredUser'] as Map<String, dynamic>?;
    return ReferralEventAdminItem(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      referralCode: (json['referralCode'] ?? '').toString(),
      courseTitle: (json['courseTitle'] ?? '').toString(),
      billingCycle: (json['billingCycle'] ?? '').toString(),
      originalAmount: (json['originalAmount'] is num)
          ? (json['originalAmount'] as num).toDouble()
          : 0,
      finalAmount: (json['finalAmount'] is num)
          ? (json['finalAmount'] as num).toDouble()
          : 0,
      refereeDiscountAmount: (json['refereeDiscountAmount'] is num)
          ? (json['refereeDiscountAmount'] as num).toDouble()
          : 0,
      referrerRewardAmount: (json['referrerRewardAmount'] is num)
          ? (json['referrerRewardAmount'] as num).toDouble()
          : 0,
      status: (json['status'] ?? 'completed').toString(),
      referrerName: (rawReferrer?['name'] ?? '').toString(),
      referrerEmail: (rawReferrer?['email'] ?? '').toString(),
      referredUserName: (rawReferredUser?['name'] ?? '').toString(),
      referredUserEmail: (rawReferredUser?['email'] ?? '').toString(),
      createdAt: (json['createdAt'] ?? '').toString().isEmpty
          ? null
          : DateTime.tryParse((json['createdAt'] ?? '').toString()),
    );
  }
}

class PromotionsAdminOverview {
  const PromotionsAdminOverview({
    this.coupons = const <CouponAdminItem>[],
    this.referralSettings = const ReferralSettings(),
    this.referralEvents = const <ReferralEventAdminItem>[],
  });

  final List<CouponAdminItem> coupons;
  final ReferralSettings referralSettings;
  final List<ReferralEventAdminItem> referralEvents;

  factory PromotionsAdminOverview.fromApi(Map<String, dynamic> json) {
    final List<dynamic> rawCoupons = (json['coupons'] as List?) ?? <dynamic>[];
    final List<dynamic> rawEvents =
        (json['referralEvents'] as List?) ?? <dynamic>[];
    return PromotionsAdminOverview(
      coupons: rawCoupons
          .whereType<Map<String, dynamic>>()
          .map(CouponAdminItem.fromApi)
          .toList(),
      referralSettings: ReferralSettings.fromApi(
        json['referralSettings'] as Map<String, dynamic>?,
      ),
      referralEvents: rawEvents
          .whereType<Map<String, dynamic>>()
          .map(ReferralEventAdminItem.fromApi)
          .toList(),
    );
  }
}
