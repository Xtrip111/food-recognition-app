import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/recipe.dart';
import '../models/app_user.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Получение пользователя по ID
  Future<AppUser?> getUser(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();

      if (doc.exists) {
        return AppUser.fromJson({
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        });
      }

      return null;
    } catch (e) {
      print('Ошибка получения пользователя: $e');
      return null;
    }
  }

  // Сохранение рецепта в истории поиска
  Future<void> saveToHistory(String userId, Recipe recipe, String imagePath) async {
    try {
      await _firestore.collection('search_history').add({
        'userId': userId,
        'recipe': recipe.toJson(),
        'imagePath': imagePath,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Ошибка сохранения истории: $e');
    }
  }

  // Получение истории поиска пользователя
  Future<List<Map<String, dynamic>>> getUserHistory(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('search_history')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(10)
          .get();

      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      print('Ошибка получения истории: $e');
      return [];
    }
  }

  // Получение общей статистики пользователя
  Future<Map<String, dynamic>> getUserStats(String userId) async {
    try {
      // Количество избранных рецептов
      final favoritesSnapshot = await _firestore
          .collection('favorites')
          .where('userId', isEqualTo: userId)
          .count()
          .get();

      // Количество запросов на поиск
      final searchSnapshot = await _firestore
          .collection('search_history')
          .where('userId', isEqualTo: userId)
          .count()
          .get();

      return {
        'favoriteRecipesCount': favoritesSnapshot.count,
        'searchesCount': searchSnapshot.count,
      };
    } catch (e) {
      print('Ошибка получения статистики: $e');
      return {
        'favoriteRecipesCount': 0,
        'searchesCount': 0,
      };
    }
  }

  // Обновление настроек пользователя
  Future<bool> updateUserSettings(String userId, Map<String, dynamic> settings) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'settings': settings,
      });
      return true;
    } catch (e) {
      print('Ошибка обновления настроек: $e');
      return false;
    }
  }

  // Получение настроек пользователя
  Future<Map<String, dynamic>> getUserSettings(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        final data = doc.data();
        return data?['settings'] ?? {};
      }
      return {};
    } catch (e) {
      print('Ошибка получения настроек: $e');
      return {};
    }
  }
}
