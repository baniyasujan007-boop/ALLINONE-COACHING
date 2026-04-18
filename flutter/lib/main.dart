import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/app_state.dart';
import 'services/auth_service.dart';
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
  await AuthService.instance.restoreSession();
  await ProgressService.instance.restore();
  final AppState appState = AppState();
  await appState.restorePreferences();
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
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
