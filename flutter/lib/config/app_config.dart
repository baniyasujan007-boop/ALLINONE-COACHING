class AppConfig {
  AppConfig._();

  // Android emulator should use 10.0.2.2 to reach localhost.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
   defaultValue: 'https://allinone-coaching.onrender.com/api',
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

  static String resolveBackendAssetUrl(String value) {
    final String raw = value.trim();
    if (raw.isEmpty) {
      return raw;
    }

    final Uri baseUri = Uri.parse(baseUrl);
    final Uri? uri = Uri.tryParse(raw);
    if (uri == null) {
      return raw;
    }

    if (!uri.hasScheme) {
      final String path = raw.startsWith('/') ? raw : '/$raw';
      return baseUri.replace(path: path, query: '', fragment: '').toString();
    }

    if (uri.scheme != 'http' && uri.scheme != 'https') {
      return raw;
    }

    const Set<String> localHosts = <String>{
      'localhost',
      '127.0.0.1',
      '10.0.2.2',
    };
    final bool isBackendUpload = uri.path.startsWith('/uploads/');
    if (!isBackendUpload || !localHosts.contains(uri.host)) {
      return raw;
    }

    return uri
        .replace(
          scheme: baseUri.scheme,
          host: baseUri.host,
          port: baseUri.hasPort ? baseUri.port : null,
        )
        .toString();
  }
}
