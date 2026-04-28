import '../models/promotion.dart';
import 'api_client.dart';

class PromotionService {
  PromotionService._();
  static final PromotionService instance = PromotionService._();

  Future<CheckoutPreview> previewCheckout({
    required String courseId,
    required String billingCycle,
    String couponCode = '',
    String referralCode = '',
  }) async {
    final dynamic json = await ApiClient.instance
        .post('/promotions/preview', <String, dynamic>{
          'courseId': courseId,
          'billingCycle': billingCycle,
          'couponCode': couponCode,
          'referralCode': referralCode,
        }, auth: true);
    if (json is! Map<String, dynamic>) {
      throw ApiException('Invalid checkout preview response');
    }
    return CheckoutPreview.fromApi(json);
  }

  Future<PromotionsAdminOverview> getAdminOverview() async {
    final dynamic json = await ApiClient.instance.get(
      '/promotions/admin',
      auth: true,
    );
    if (json is! Map<String, dynamic>) {
      throw ApiException('Invalid promotions response');
    }
    return PromotionsAdminOverview.fromApi(json);
  }

  Future<void> createCoupon(Map<String, dynamic> data) async {
    await ApiClient.instance.post(
      '/promotions/admin/coupons',
      data,
      auth: true,
    );
  }

  Future<void> updateCoupon(String id, Map<String, dynamic> data) async {
    await ApiClient.instance.put(
      '/promotions/admin/coupons/$id',
      data,
      auth: true,
    );
  }

  Future<void> deleteCoupon(String id) async {
    await ApiClient.instance.delete(
      '/promotions/admin/coupons/$id',
      auth: true,
    );
  }

  Future<void> updateReferralSettings(ReferralSettings settings) async {
    await ApiClient.instance.put(
      '/promotions/admin/referral-settings',
      settings.toJson(),
      auth: true,
    );
  }
}
