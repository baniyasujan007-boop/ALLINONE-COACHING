import 'dart:convert';
import 'dart:typed_data';

import 'api_client.dart';

class AiDoubtService {
  AiDoubtService._();
  static final AiDoubtService instance = AiDoubtService._();

  Future<String> solveDoubt({
    String? question,
    Uint8List? imageBytes,
    String? imageMimeType,
  }) async {
    final Map<String, dynamic> payload = <String, dynamic>{};
    if (question != null && question.trim().isNotEmpty) {
      payload['question'] = question.trim();
    }
    if (imageBytes != null && imageBytes.isNotEmpty) {
      payload['imageBase64'] = base64Encode(imageBytes);
      payload['imageMimeType'] =
          (imageMimeType == null || imageMimeType.trim().isEmpty)
          ? 'image/jpeg'
          : imageMimeType.trim();
    }

    final dynamic json = await ApiClient.instance.post(
      '/ai/doubt-solve',
      payload,
      auth: true,
    );
    if (json is! Map<String, dynamic>) {
      throw ApiException('Invalid AI response');
    }
    final String explanation = (json['explanation'] ?? '').toString().trim();
    if (explanation.isEmpty) {
      throw ApiException('AI response was empty');
    }
    return explanation;
  }
}
