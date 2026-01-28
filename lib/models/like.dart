class Like {
  final int id;
  final DateTime? createdAt;
  final int postId;
  final String userId;

  Like({
    required this.id,
    this.createdAt,
    required this.postId,
    required this.userId,
  });

  factory Like.fromJson(Map<String, dynamic> json) {
    return Like(
      id: json['id'] as int,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      postId: json['post_id'] as int,
      userId: json['user_id'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      'post_id': postId,
      'user_id': userId,
    };
  }

  Like copyWith({
    int? id,
    DateTime? createdAt,
    int? postId,
    String? userId,
  }) {
    return Like(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      postId: postId ?? this.postId,
      userId: userId ?? this.userId,
    );
  }

  @override
  String toString() {
    return 'Like(id: $id, postId: $postId, userId: $userId)';
  }
}
