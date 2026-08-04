import 'dart:io';

class AdService {
  // App IDs
  static String get appId => Platform.isAndroid
      ? 'ca-app-pub-7848108794028172~7386956411'
      : '';

  // Banner Ad Unit
  static String get bannerAdUnitId => Platform.isAndroid
      ? 'ca-app-pub-7848108794028172/3437771411'
      : '';

  // Interstitial Ad Unit
  static String get interstitialAdUnitId => Platform.isAndroid
      ? 'ca-app-pub-7848108794028172/4435012522'
      : '';

  // Rewarded Ad Unit
  static String get rewardedAdUnitId => Platform.isAndroid
      ? 'ca-app-pub-7848108794028172/2875232855'
      : '';
}