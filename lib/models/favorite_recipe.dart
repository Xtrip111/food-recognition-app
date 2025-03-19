import 'package:cloud_firestore/cloud_firestore.dart';
import 'recipe.dart';

class FavoriteRecipe {
  final String id;
  final String userId;
  final Recipe recipe;
  final DateTime savedAt;
  final String? notes;
  final String? imagePath;

  FavoriteRecipe({
    required this.id,
    required this.userId,
    required this.recipe,
    DateTime? savedAt,
    this.notes,
    this.imagePath,
  }) : savedAt = savedAt ?? DateTime.now();

  factory FavoriteRecipe.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FavoriteRecipe(
      id: doc.id,
      userId: data['userId'] ?? '',
      recipe: Recipe.fromJson(data['recipe'] ?? {}),
      savedAt: data['savedAt'] != null
          ? (data['savedAt'] as Timestamp).toDate()
          : DateTime.now(),
      notes: data['notes'],
      imagePath: data['imagePath'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'recipe': recipe.toJson(),
      'savedAt': Timestamp.fromDate(savedAt),
      'notes': notes,
      'imagePath': imagePath,
    };
  }

  // Создает копию с обновленными полями
  FavoriteRecipe copyWith({
    String? notes,
    String? imagePath,
  }) {
    return FavoriteRecipe(
      id: this.id,
      userId: this.userId,
      recipe: this.recipe,
      savedAt: this.savedAt,
      notes: notes ?? this.notes,
      imagePath: imagePath ?? this.imagePath,
    );
  }
}
