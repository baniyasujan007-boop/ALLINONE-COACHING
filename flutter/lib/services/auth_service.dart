import 'package:google_sign_in/google_sign_in.dart';
import '../models/app_user.dart';
import '../models/admin_user.dart';
import 'api_client.dart';
import 'dart:typed_data';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';

class AuthSession {
  const AuthSession({required this.user, required this.token});

  final AppUser user;
  final String token;
}

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();
  static const String _tokenKey = 'auth_token';
  static const List<String> _googleUserInfoScopes = <String>[
    'https://www.googleapis.com/auth/userinfo.email',
    'https://www.googleapis.com/auth/userinfo.profile',
  ];
  static final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  AuthSession? _currentSession;
  bool _googleInitialized = false;
  String? _googleInitializationError;

  AuthSession? get currentSession => _currentSession;

  void seedDefaults() {
    // No-op for API-backed auth flow.
  }

  Future<void> initializeGoogleSignIn() async {
    if (_googleInitialized) {
      return;
    }
    try {
      await _googleSignIn.initialize(
        clientId: AppConfig.googleClientId.isEmpty
            ? null
            : AppConfig.googleClientId,
        serverClientId: AppConfig.googleServerClientId.isEmpty
            ? null
            : AppConfig.googleServerClientId,
      );
      _googleInitialized = true;
      _googleInitializationError = null;
    } catch (error) {
      _googleInitializationError = error.toString();
      rethrow;
    }
  }

  Future<void> restoreSession() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString(_tokenKey);
    if (token == null || token.isEmpty) {
      return;
    }
    ApiClient.instance.setToken(token);
    try {
      final dynamic json = await ApiClient.instance.get('/auth/me', auth: true);
      if (json is! Map<String, dynamic>) {
        await logout();
        return;
      }
      final AppUser user = AppUser.fromApi(json);
      _currentSession = AuthSession(user: user, token: token);
    } catch (_) {
      await logout();
    }
  }

  Future<String?> registerStudent({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      await ApiClient.instance.post('/auth/register', <String, dynamic>{
        'name': name.trim(),
        'email': email.trim().toLowerCase(),
        'password': password,
        'role': 'student',
      });
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'Registration failed. Please try again.';
    }
  }

  Future<String?> login({
    required String email,
    required String password,
  }) async {
    try {
      final dynamic json = await ApiClient.instance.post(
        '/auth/login',
        <String, dynamic>{
          'email': email.trim().toLowerCase(),
          'password': password,
        },
      );
      if (json is! Map<String, dynamic>) {
        return 'Unexpected login response';
      }
      final AppUser user = AppUser.fromApi(json);
      final String token = (json['token'] ?? '').toString();
      if (token.isEmpty || user.id.isEmpty) {
        return 'Invalid login response';
      }
      _currentSession = AuthSession(user: user, token: token);
      ApiClient.instance.setToken(token);
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'Login failed. Please try again.';
    }
  }

  Future<String?> loginWithGoogle() async {
    try {
      await initializeGoogleSignIn();
      if (_googleInitializationError != null) {
        return 'Google sign-in is not configured correctly: $_googleInitializationError';
      }

      final GoogleSignInAccount account = await _googleSignIn.authenticate(
        scopeHint: _googleUserInfoScopes,
      );
      final String? idToken = account.authentication.idToken;
      final String? accessToken = await _googleAccessTokenFor(account);

      if ((idToken == null || idToken.isEmpty) &&
          (accessToken == null || accessToken.isEmpty)) {
        return _googleTokenConfigurationMessage();
      }

      final Map<String, dynamic> payload = <String, dynamic>{};
      if (idToken != null && idToken.isNotEmpty) {
        payload['idToken'] = idToken;
      }
      if (accessToken != null && accessToken.isNotEmpty) {
        payload['accessToken'] = accessToken;
      }

      final dynamic json = await ApiClient.instance.post(
        '/auth/google',
        payload,
      );
      if (json is! Map<String, dynamic>) {
        return 'Unexpected Google login response';
      }

      final AppUser user = AppUser.fromApi(json);
      final String token = (json['token'] ?? '').toString();
      if (token.isEmpty || user.id.isEmpty) {
        return 'Invalid Google login response';
      }

      _currentSession = AuthSession(user: user, token: token);
      ApiClient.instance.setToken(token);
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
      return null;
    } on GoogleSignInException catch (e) {
      switch (e.code) {
        case GoogleSignInExceptionCode.canceled:
          return 'Google sign-in was canceled or rejected by Google. On Android this usually means the OAuth setup does not match this app package/SHA yet.';
        case GoogleSignInExceptionCode.uiUnavailable:
          return 'Google sign-in UI is unavailable on this device';
        default:
          return e.description ?? 'Google sign-in failed';
      }
    } on ApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'Google sign-in failed. Please try again.';
    }
  }

  Future<void> logout() async {
    _currentSession = null;
    ApiClient.instance.setToken(null);
    try {
      await _googleSignIn.signOut();
    } catch (_) {
      // Ignore Google SDK sign-out failures so local logout still completes.
    }
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  Future<String?> _googleAccessTokenFor(GoogleSignInAccount account) async {
    try {
      final GoogleSignInClientAuthorization? cachedAuthorization = await account
          .authorizationClient
          .authorizationForScopes(_googleUserInfoScopes);
      if (cachedAuthorization != null &&
          cachedAuthorization.accessToken.isNotEmpty) {
        return cachedAuthorization.accessToken;
      }

      final GoogleSignInClientAuthorization authorization = await account
          .authorizationClient
          .authorizeScopes(_googleUserInfoScopes);
      return authorization.accessToken.isEmpty
          ? null
          : authorization.accessToken;
    } on GoogleSignInException {
      return null;
    } catch (_) {
      return null;
    }
  }

  String _googleTokenConfigurationMessage() {
    final List<String> missing = <String>[];
    if (AppConfig.googleServerClientId.isEmpty) {
      missing.add('GOOGLE_SERVER_CLIENT_ID');
    }
    if (missing.isEmpty) {
      return 'Google sign-in did not return an ID token or access token. Check your Android/iOS OAuth client setup and installed Google configuration files.';
    }
    return 'Google sign-in did not return an ID token or access token. Add ${missing.join(', ')} to your Flutter run configuration and ensure your Google OAuth clients are configured for this app.';
  }

  Future<String?> forgotPassword({
    required String email,
    required String newPassword,
  }) async {
    try {
      await ApiClient.instance.post('/auth/forgot-password', <String, dynamic>{
        'email': email.trim().toLowerCase(),
        'newPassword': newPassword,
      });
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'Failed to reset password. Please try again.';
    }
  }

  Future<String?> refreshProfile() async {
    if (_currentSession == null) {
      return 'You are not logged in';
    }
    try {
      final dynamic json = await ApiClient.instance.get('/auth/me', auth: true);
      if (json is! Map<String, dynamic>) {
        return 'Invalid profile response';
      }
      final AppUser updated = AppUser.fromApi(json);
      _currentSession = AuthSession(
        user: updated,
        token: _currentSession!.token,
      );
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'Failed to fetch profile';
    }
  }

  Future<String?> updateProfile({
    required String name,
    required String email,
    required String phone,
    required String address,
    required String profileImage,
  }) async {
    if (_currentSession == null) {
      return 'You are not logged in';
    }
    try {
      final Map<String, dynamic> payload = <String, dynamic>{
        'name': name.trim(),
        'email': email.trim().toLowerCase(),
        'phone': phone.trim(),
        'address': address.trim(),
        'profileImage': profileImage.trim(),
      };

      final dynamic json = await ApiClient.instance.put(
        '/auth/me',
        payload,
        auth: true,
      );
      if (json is! Map<String, dynamic>) {
        return 'Invalid profile response';
      }
      final AppUser updated = AppUser.fromApi(
        json,
      ).copyWith(role: _currentSession!.user.role);
      _currentSession = AuthSession(
        user: updated,
        token: _currentSession!.token,
      );
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'Failed to update profile';
    }
  }

  Future<List<AdminUser>> getUsersForAdmin() async {
    final dynamic json = await ApiClient.instance.get(
      '/auth/users',
      auth: true,
    );
    if (json is! List) {
      throw ApiException('Invalid users response');
    }
    return json
        .whereType<Map<String, dynamic>>()
        .map(AdminUser.fromApi)
        .toList();
  }

  Future<AdminUser> updateUserByAdmin({
    required String userId,
    required String name,
    required String email,
    required String role,
    required String phone,
    required String address,
    required String profileImage,
    required List<String> enrolledCourseIds,
  }) async {
    final dynamic json = await ApiClient.instance
        .put('/auth/users/$userId', <String, dynamic>{
          'name': name.trim(),
          'email': email.trim().toLowerCase(),
          'role': role,
          'phone': phone.trim(),
          'address': address.trim(),
          'profileImage': profileImage.trim(),
          'enrolledCourseIds': enrolledCourseIds,
        }, auth: true);
    if (json is! Map<String, dynamic>) {
      throw ApiException('Invalid user response');
    }
    return AdminUser.fromApi(json);
  }

  Future<String> uploadProfileImage({
    required Uint8List bytes,
    required String filename,
  }) async {
    final dynamic json = await ApiClient.instance.uploadFile(
      '/upload/profile-image',
      bytes: bytes,
      filename: filename,
      auth: true,
    );
    if (json is! Map<String, dynamic>) {
      throw ApiException('Invalid upload response');
    }
    final String url = (json['url'] ?? '').toString();
    if (url.isEmpty) {
      throw ApiException('Profile image upload failed');
    }
    return url;
  }
}
