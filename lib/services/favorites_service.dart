import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/recipe.dart';
import '../models/favorite_recipe.dart';
import '../auth/auth_service.dart';


class FavoritesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();

  // Добавление рецепта в избранное
  Future<String?> addToFavorites(Recipe recipe, String? imagePath) async {
    try {
      final user = _authService.currentUser;
      if (user == null) return null;

      // Создаем запись в коллекции favorites
      final docRef = await _firestore.collection('favorites').add({
        'userId': user.uid,
        'recipe': recipe.toJson(),
        'savedAt': FieldValue.serverTimestamp(),
        'imagePath': imagePath,
      });

      // Обновляем список избранного в документе пользователя
      await _authService.addToFavorites(docRef.id);

      return docRef.id;
    } catch (e) {
      print('Ошибка добавления в избранное: $e');
      return null;
    }
  }

  // Получение всех избранных рецептов пользователя
  Stream<List<FavoriteRecipe>> getUserFavorites() {
    final user = _authService.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('favorites')
        .where('userId', isEqualTo: user.uid)
        .orderBy('savedAt', descending: true)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => FavoriteRecipe.fromFirestore(doc)).toList());
  }

  // Удаление рецепта из избранного
  Future<bool> removeFromFavorites(String favoriteId) async {
    try {
      final user = _authService.currentUser;
      if (user == null) return false;

      // Удаляем документ из коллекции favorites
      await _firestore.collection('favorites').doc(favoriteId).delete();

      // Обновляем список избранного в документе пользователя
      await _authService.removeFromFavorites(favoriteId);

      return true;
    } catch (e) {
      print('Ошибка удаления из избранного: $e');
      return false;
    }
  }

  // Проверка, находится ли рецепт в избранном
  Future<bool> isInFavorites(String recipeId) async {
    try {
      final user = _authService.currentUser;
      if (user == null) return false;

      final snapshot = await _firestore
          .collection('favorites')
          .where('userId', isEqualTo: user.uid)
          .where('recipeId', isEqualTo: recipeId)
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print('Ошибка проверки избранного: $e');
      return false;
    }
  }

  // Получение количества избранных рецептов пользователя
  Future<int> getFavoritesCount() async {
    try {
      final user = _authService.currentUser;
      if (user == null) return 0;

      final snapshot = await _firestore
          .collection('favorites')
          .where('userId', isEqualTo: user.uid)
          .count()
          .get();

      return snapshot.count ?? 0;
    } catch (e) {
      print('Ошибка получения количества избранного: $e');
      return 0;
    }
  }
}
