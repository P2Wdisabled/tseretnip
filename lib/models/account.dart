class Account {
  final String id;
  final DateTime? createdAt;
  final String? username;
  final String? description;
  final String? avatar;
  final String? theme;
  final String? banner;

  Account({
    required this.id,
    this.createdAt,
    this.username,
    this.description,
    this.avatar,
    this.theme,
    this.banner,
  });

  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      id: json['id'] as String,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      username: json['username']?.toString(),
      description: json['description']?.toString(),
      avatar: json['avatar']?.toString(),
      theme: json['theme']?.toString(),
      banner: json['banner']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (username != null) 'username': username,
      if (description != null) 'description': description,
      if (avatar != null) 'avatar': avatar,
      if (theme != null) 'theme': theme,
      if (banner != null) 'banner': banner,
    };
  }

  Account copyWith({
    String? id,
    DateTime? createdAt,
    String? username,
    String? description,
    String? avatar,
    String? theme,
    String? banner,
  }) {
    return Account(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      username: username ?? this.username,
      description: description ?? this.description,
      avatar: avatar ?? this.avatar,
      theme: theme ?? this.theme,
      banner: banner ?? this.banner,
    );
  }

  @override
  String toString() {
    return 'Account(id: $id, username: $username)';
  }
}
