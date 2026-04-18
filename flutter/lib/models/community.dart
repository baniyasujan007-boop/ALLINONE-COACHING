class CommunityAnswer {
  const CommunityAnswer({
    required this.id,
    required this.authorName,
    required this.message,
    required this.createdAt,
    this.imageUrl,
    this.imageName,
  });

  final String id;
  final String authorName;
  final String message;
  final DateTime createdAt;
  final String? imageUrl;
  final String? imageName;
}

class CommunityPost {
  const CommunityPost({
    required this.id,
    required this.topic,
    required this.authorName,
    required this.title,
    required this.message,
    required this.createdAt,
    required this.answers,
    this.imageUrl,
    this.imageName,
  });

  final String id;
  final String topic;
  final String authorName;
  final String title;
  final String message;
  final DateTime createdAt;
  final List<CommunityAnswer> answers;
  final String? imageUrl;
  final String? imageName;

  CommunityPost copyWith({
    String? id,
    String? topic,
    String? authorName,
    String? title,
    String? message,
    DateTime? createdAt,
    List<CommunityAnswer>? answers,
    String? imageUrl,
    String? imageName,
  }) {
    return CommunityPost(
      id: id ?? this.id,
      topic: topic ?? this.topic,
      authorName: authorName ?? this.authorName,
      title: title ?? this.title,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      answers: answers ?? this.answers,
      imageUrl: imageUrl ?? this.imageUrl,
      imageName: imageName ?? this.imageName,
    );
  }
}
