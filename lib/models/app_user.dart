class AppUser {
  final String id;
  final String email;
  final String displayName;
  final String? photoUrl;
  final String? bio;
  final List<String> favoriteRecipes;
  final DateTime createdAt;
  final DateTime? lastLogin;

  AppUser({
    required this.id,
    required this.email,
    required this.displayName,
    this.photoUrl,
    this.bio,
    List<String>? favoriteRecipes,
    DateTime? createdAt,
    this.lastLogin,
  })  : favoriteRecipes = favoriteRecipes ?? [],
        createdAt = createdAt ?? DateTime.now();

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      displayName: json['displayName'] ?? '',
      photoUrl: json['photoUrl'],
      bio: json['bio'],
      favoriteRecipes: json['favoriteRecipes'] != null
          ? List<String>.from(json['favoriteRecipes'])
          : [],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      lastLogin: json['lastLogin'] != null
          ? DateTime.parse(json['lastLogin'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'bio': bio,
      'favoriteRecipes': favoriteRecipes,
      'createdAt': createdAt.toIso8601String(),
      'lastLogin': lastLogin?.toIso8601String(),
    };
  }

  // Создает копию с обновленными полями
  AppUser copyWith({
    String? displayName,
    String? photoUrl,
    String? bio,
    List<String>? favoriteRecipes,
    DateTime? lastLogin,
  }) {
    return AppUser(
      id: this.id,
      email: this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      bio: bio ?? this.bio,
      favoriteRecipes: favoriteRecipes ?? this.favoriteRecipes,
      createdAt: this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
    );
  }
}
