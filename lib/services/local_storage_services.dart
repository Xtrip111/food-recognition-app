import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/recipe.dart';

class LocalStorageService {
  static const String _favoriteRecipesKey = 'favorite_recipes';
  static const String _recentSearchesKey = 'recent_searches';
  static const String _lastLoginKey = 'last_login';

  // Сохранение избранного рецепта локально
  Future<bool> saveFavoriteRecipeLocally(String recipeId, Recipe recipe) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoritesJson = prefs.getString(_favoriteRecipesKey) ?? '{}';
      final Map<String, dynamic> favoritesMap = json.decode(favoritesJson);

      favoritesMap[recipeId] = recipe.toJson();
      await prefs.setString(_favoriteRecipesKey, json.encode(favoritesMap));
      return true;
    } catch (e) {
      print('Ошибка сохранения избранного рецепта локально: $e');
      return false;
    }
  }

  // Получение локально сохраненного избранного рецепта
  Future<Recipe?> getFavoriteRecipeLocally(String recipeId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoritesJson = prefs.getString(_favoriteRecipesKey) ?? '{}';
      final Map<String, dynamic> favoritesMap = json.decode(favoritesJson);

      if (favoritesMap.containsKey(recipeId)) {
        return Recipe.fromJson(favoritesMap[recipeId]);
      }
      return null;
    } catch (e) {
      print('Ошибка получения избранного рецепта локально: $e');
      return null;
    }
  }

  // Удаление избранного рецепта из локального хранилища
  Future<bool> removeFavoriteRecipeLocally(String recipeId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoritesJson = prefs.getString(_favoriteRecipesKey) ?? '{}';
      final Map<String, dynamic> favoritesMap = json.decode(favoritesJson);

      if (favoritesMap.containsKey(recipeId)) {
        favoritesMap.remove(recipeId);
        await prefs.setString(_favoriteRecipesKey, json.encode(favoritesMap));
      }
      return true;
    } catch (e) {
      print('Ошибка удаления избранного рецепта локально: $e');
      return false;
    }
  }

  // Сохранение последних поисков
  Future<bool> saveRecentSearch(String search) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> searches = prefs.getStringList(_recentSearchesKey) ?? [];

      // Удаляем дубликаты и добавляем новый поиск в начало списка
      searches.remove(search);
      searches.insert(0, search);

      // Ограничиваем список 10 последними поисками
      if (searches.length > 10) {
        searches.removeLast();
      }

      await prefs.setStringList(_recentSearchesKey, searches);
      return true;
    } catch (e) {
      print('Ошибка сохранения последних поисков: $e');
      return false;
    }
  }

  // Получение последних поисков
  Future<List<String>> getRecentSearches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList(_recentSearchesKey) ?? [];
    } catch (e) {
      print('Ошибка получения последних поисков: $e');
      return [];
    }
  }

  // Очистка последних поисков
  Future<bool> clearRecentSearches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_recentSearchesKey);
      return true;
    } catch (e) {
      print('Ошибка очистки последних поисков: $e');
      return false;
    }
  }

  // Сохранение времени последнего входа
  Future<bool> saveLastLogin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastLoginKey, DateTime.now().toIso8601String());
      return true;
    } catch (e) {
      print('Ошибка сохранения времени последнего входа: $e');
      return false;
    }
  }

  // Получение времени последнего входа
  Future<DateTime?> getLastLogin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastLoginString = prefs.getString(_lastLoginKey);
      if (lastLoginString != null) {
        return DateTime.parse(lastLoginString);
      }
      return null;
    } catch (e) {
      print('Ошибка получения времени последнего входа: $e');
      return null;
    }
  }
}
