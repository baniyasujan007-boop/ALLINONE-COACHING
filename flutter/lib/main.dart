import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';

import 'providers/app_state.dart';
import 'services/community_service.dart';
import 'services/progress_service.dart';
import 'screens/splash_screen.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await AuthService.instance.initializeGoogleSignIn();
  } catch (_) {
    // Let the app boot even if Google sign-in is not configured yet.
  }

  try {
    await AuthService.instance.restoreSession()
        .timeout(const Duration(seconds: 10));
  } catch (_) {
    // Continue launching the app even if restore fails
  }

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
