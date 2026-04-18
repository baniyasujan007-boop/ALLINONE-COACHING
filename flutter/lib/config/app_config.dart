class AppConfig {
  AppConfig._();

  // Android emulator should use 10.0.2.2 to reach localhost.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:5001/api',
  );

  static const String googleClientId = String.fromEnvironment(
    'GOOGLE_CLIENT_ID',
    defaultValue: '',
  );

  static const String googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue:
        '688886667397-fa9p57du36locdsdrjb11u38kte0oebr.apps.googleusercontent.com',
  );
}
