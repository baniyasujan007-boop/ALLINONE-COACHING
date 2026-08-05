import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart' hide AppState;
import 'package:flutter_web_plugins/url_strategy.dart';
import 'providers/app_state.dart';
import 'services/community_service.dart';
import 'services/progress_service.dart';
import 'screens/splash_screen.dart';
import 'pages/legal/account_deletion_page.dart';
import 'pages/legal/privacy_policy_page.dart';
import 'theme.dart';

Future<void> main() async {
  // Uses clean web URLs such as /account-deletion instead of hash URLs.
  usePathUrlStrategy();
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Google Mobile Ads
  await MobileAds.instance.initialize();

  try {
    await AuthService.instance.initializeGoogleSignIn();
  } catch (_) {}

  try {
    await AuthService.instance.restoreSession().timeout(
      const Duration(seconds: 10),
    );
  } catch (_) {}

  try {
    await ProgressService.instance.restore();
  } catch (_) {}

  final AppState appState = AppState();

  try {
    await appState.restorePreferences();
  } catch (_) {}

  try {
    await appState.recordDailyEngagement();
  } catch (_) {}

  runApp(AllInOneCoachingApp(appState: appState));
}

class AllInOneCoachingApp extends StatelessWidget {
  const AllInOneCoachingApp({super.key, required this.appState});

  final AppState appState;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AppState>.value(value: appState),
        ChangeNotifierProvider<CommunityService>.value(
          value: CommunityService.instance,
        ),
        ChangeNotifierProvider<ProgressService>.value(
          value: ProgressService.instance,
        ),
      ],
      child: Consumer<AppState>(
        builder: (BuildContext context, AppState appState, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'All in One Coaching',
            themeMode: appState.darkMode ? ThemeMode.dark : ThemeMode.light,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            routes: <String, WidgetBuilder>{
              PrivacyPolicyPage.routeName: (_) => const PrivacyPolicyPage(),
              AccountDeletionPage.routeName: (_) => const AccountDeletionPage(),
            },
            builder: (BuildContext context, Widget? child) {
              return SafeArea(child: child ?? const SizedBox.shrink());
            },
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
