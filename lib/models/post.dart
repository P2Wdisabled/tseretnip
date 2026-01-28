import 'package:tseretnip/models/account.dart';

class Post {
  final int id;
  final String userId;
  final String? image;
  final DateTime? createdAt;
  final int likeCount;
  final Account? author;

  Post({
    required this.id,
    required this.userId,
    this.image,
    this.createdAt,
    this.likeCount = 0,
    this.author,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    // Parse like count from Supabase aggregation: likes(count) returns [{count: N}]
    int parsedLikeCount = 0;
    if (json['likes'] != null) {
      final likesData = json['likes'] as List<dynamic>;
      if (likesData.isNotEmpty && likesData[0]['count'] != null) {
        parsedLikeCount = likesData[0]['count'] as int;
      }
    }

    // Parse author from joined accounts table
    Account? parsedAuthor;
    if (json['accounts'] != null) {
      parsedAuthor = Account.fromJson(json['accounts'] as Map<String, dynamic>);
    }

    return Post(
      id: json['id'] as int,
      userId: json['user_id'] as String,
      image: json['image'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      likeCount: parsedLikeCount,
      author: parsedAuthor,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      if (image != null) 'image': image,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }

  Post copyWith({
    int? id,
    String? userId,
    String? image,
    DateTime? createdAt,
    int? likeCount,
    Account? author,
  }) {
    return Post(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      image: image ?? this.image,
      createdAt: createdAt ?? this.createdAt,
      likeCount: likeCount ?? this.likeCount,
      author: author ?? this.author,
    );
  }

  @override
  String toString() {
    return 'Post(id: $id, userId: $userId, likeCount: $likeCount)';
  }
}
