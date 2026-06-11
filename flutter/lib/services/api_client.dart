import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();
  static const Duration _requestTimeout = Duration(seconds: 15);

  String? _token;

  void setToken(String? token) {
    _token = token;
  }

  Uri _uri(String path) {
    final String cleaned = path.startsWith('/') ? path.substring(1) : path;
    return Uri.parse('${AppConfig.baseUrl}/$cleaned');
  }

  Map<String, String> _headers({bool auth = false}) {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (auth && _token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  dynamic _decodeBody(http.Response response) {
    if (response.body.isEmpty) {
      return null;
    }
    return jsonDecode(response.body);
  }

  dynamic _handleResponse(http.Response response) {
    final dynamic body = _decodeBody(response);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }
    String message = 'Request failed';
    if (body is Map) {
      if (body['errors'] is List && (body['errors'] as List).isNotEmpty) {
        final List<String> msgs = (body['errors'] as List)
            .whereType<Map>()
            .map((Map e) => (e['message'] ?? '').toString())
            .where((String e) => e.isNotEmpty)
            .toList();
        if (msgs.isNotEmpty) {
          message = msgs.join(', ');
        } else if (body['message'] is String) {
          message = body['message'] as String;
        }
      } else if (body['message'] is String) {
        message = body['message'] as String;
      }
    }
    throw ApiException(message, statusCode: response.statusCode);
  }

  String _networkErrorMessage() {
    final StringBuffer message = StringBuffer(
      'Cannot reach the backend server at ${AppConfig.baseUrl}.',
    );
    if (AppConfig.baseUrl.contains('10.0.2.2')) {
      message.write(
        ' If you are using a physical phone, 10.0.2.2 only works on the Android emulator. Run the app with API_BASE_URL set to your computer LAN IP, for example https://allinone-coaching.onrender.com',
      );
    } else {
      message.write(
        ' Make sure your backend is running and your phone and computer are on the same Wi-Fi.',
      );
    }
    return message.toString();
  }

  Future<dynamic> get(String path, {bool auth = false}) async {
    try {
      final response = await http
          .get(_uri(path), headers: _headers(auth: auth))
          .timeout(_requestTimeout);
      return _handleResponse(response);
    } on TimeoutException {
      throw ApiException(_networkErrorMessage());
    } on http.ClientException {
      throw ApiException(_networkErrorMessage());
    }
  }

  Future<dynamic> post(
    String path,
    Map<String, dynamic> data, {
    bool auth = false,
  }) async {
    try {
      final response = await http
          .post(
            _uri(path),
            headers: _headers(auth: auth),
            body: jsonEncode(data),
          )
          .timeout(_requestTimeout);
      return _handleResponse(response);
    } on TimeoutException {
      throw ApiException(_networkErrorMessage());
    } on http.ClientException {
      throw ApiException(_networkErrorMessage());
    }
  }

  Future<dynamic> put(
    String path,
    Map<String, dynamic> data, {
    bool auth = false,
  }) async {
    try {
      final response = await http
          .put(
            _uri(path),
            headers: _headers(auth: auth),
            body: jsonEncode(data),
          )
          .timeout(_requestTimeout);
      return _handleResponse(response);
    } on TimeoutException {
      throw ApiException(_networkErrorMessage());
    } on http.ClientException {
      throw ApiException(_networkErrorMessage());
    }
  }

  Future<dynamic> delete(String path, {bool auth = false}) async {
    try {
      final response = await http
          .delete(_uri(path), headers: _headers(auth: auth))
          .timeout(_requestTimeout);
      return _handleResponse(response);
    } on TimeoutException {
      throw ApiException(_networkErrorMessage());
    } on http.ClientException {
      throw ApiException(_networkErrorMessage());
    }
  }

  Future<dynamic> uploadFile(
    String path, {
    required Uint8List bytes,
    required String filename,
    String fieldName = 'file',
    bool auth = false,
  }) async {
    try {
      final request = http.MultipartRequest('POST', _uri(path));
      if (auth && _token != null) {
        request.headers['Authorization'] = 'Bearer $_token';
      }
      request.files.add(
        http.MultipartFile.fromBytes(fieldName, bytes, filename: filename),
      );

      final streamed = await request.send().timeout(_requestTimeout);
      final response = await http.Response.fromStream(streamed);
      return _handleResponse(response);
    } on TimeoutException {
      throw ApiException(_networkErrorMessage());
    } on http.ClientException {
      throw ApiException(_networkErrorMessage());
    }
  }
}
