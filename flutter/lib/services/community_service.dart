import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../models/community.dart';
import 'api_client.dart';

class CommunityService extends ChangeNotifier {
  CommunityService._();

  static final CommunityService instance = CommunityService._();

  final List<CommunityPost> _posts = <CommunityPost>[];
  bool _loading = false;
  String? _error;
  bool _loadedOnce = false;

  List<CommunityPost> get posts => List<CommunityPost>.unmodifiable(_posts);
  bool get loading => _loading;
  String? get error => _error;

  List<String> get topics {
    final List<String> topicList = _posts
        .map((CommunityPost post) => post.topic)
        .toSet()
        .toList()
      ..sort();
    return <String>['All', ...topicList];
  }

  Future<void> loadPosts({bool force = false}) async {
    if (_loadedOnce && !force) {
      return;
    }
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final dynamic json = await ApiClient.instance.get('/community', auth: true);
      if (json is! List) {
        throw ApiException('Invalid community response');
      }
      _posts
        ..clear()
        ..addAll(
          json
              .whereType<Map<String, dynamic>>()
              .map((Map<String, dynamic> item) => _postFromJson(item)),
        );
      _loadedOnce = true;
    } on ApiException catch (error) {
      _error = error.message;
    } catch (_) {
      _error = 'Failed to load community posts';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> createPost({
    required String topic,
    required String title,
    required String message,
    Uint8List? imageBytes,
    String? imageName,
  }) async {
    String imageUrl = '';
    String uploadedName = imageName ?? '';
    if (imageBytes != null && uploadedName.isNotEmpty) {
      final dynamic uploadJson = await ApiClient.instance.uploadFile(
        '/upload/community-image',
        bytes: imageBytes,
        filename: uploadedName,
        auth: true,
      );
      if (uploadJson is Map<String, dynamic>) {
        imageUrl = (uploadJson['url'] ?? '').toString();
        uploadedName = (uploadJson['originalName'] ?? uploadedName).toString();
      }
    }

    final dynamic json = await ApiClient.instance.post(
      '/community/posts',
      <String, dynamic>{
        'topic': topic,
        'title': title,
        'message': message,
        'imageUrl': imageUrl,
        'imageName': uploadedName,
      },
      auth: true,
    );
    if (json is! Map<String, dynamic>) {
      throw ApiException('Invalid community post response');
    }

    _posts.insert(0, _postFromJson(json));
    _loadedOnce = true;
    notifyListeners();
  }

  Future<void> createAnswer({
    required String postId,
    required String message,
    Uint8List? imageBytes,
    String? imageName,
  }) async {
    String imageUrl = '';
    String uploadedName = imageName ?? '';
    if (imageBytes != null && uploadedName.isNotEmpty) {
      final dynamic uploadJson = await ApiClient.instance.uploadFile(
        '/upload/community-image',
        bytes: imageBytes,
        filename: uploadedName,
        auth: true,
      );
      if (uploadJson is Map<String, dynamic>) {
        imageUrl = (uploadJson['url'] ?? '').toString();
        uploadedName = (uploadJson['originalName'] ?? uploadedName).toString();
      }
    }

    final dynamic json = await ApiClient.instance.post(
      '/community/posts/$postId/answers',
      <String, dynamic>{
        'message': message,
        'imageUrl': imageUrl,
        'imageName': uploadedName,
      },
      auth: true,
    );
    if (json is! Map<String, dynamic>) {
      throw ApiException('Invalid community answer response');
    }

    final CommunityPost updated = _postFromJson(json);
    final int index = _posts.indexWhere((CommunityPost post) => post.id == postId);
    if (index >= 0) {
      _posts[index] = updated;
    } else {
      _posts.insert(0, updated);
    }
    _loadedOnce = true;
    notifyListeners();
  }

  CommunityPost _postFromJson(Map<String, dynamic> json) {
    final List<CommunityAnswer> answers =
        ((json['answers'] as List?) ?? <dynamic>[])
            .whereType<Map<String, dynamic>>()
            .map(_answerFromJson)
            .toList();

    return CommunityPost(
      id: (json['id'] ?? '').toString(),
      topic: (json['topic'] ?? '').toString(),
      authorName: (json['authorName'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      message: (json['message'] ?? '').toString(),
      createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()) ??
          DateTime.now(),
      answers: answers,
      imageUrl: _optionalString(json['imageUrl']),
      imageName: _optionalString(json['imageName']),
    );
  }

  CommunityAnswer _answerFromJson(Map<String, dynamic> json) {
    return CommunityAnswer(
      id: (json['id'] ?? '').toString(),
      authorName: (json['authorName'] ?? '').toString(),
      message: (json['message'] ?? '').toString(),
      createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()) ??
          DateTime.now(),
      imageUrl: _optionalString(json['imageUrl']),
      imageName: _optionalString(json['imageName']),
    );
  }

  String? _optionalString(dynamic value) {
    final String text = (value ?? '').toString().trim();
    return text.isEmpty ? null : text;
  }
}
