import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'auth_service.dart';
import '../models/app_user.dart';

class UserProvider with ChangeNotifier {
  AppUser? _user;
  bool _isLoading = false;
  final AuthService _authService = AuthService();

  AppUser? get user => _user;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _user != null;

  UserProvider() {
    _initUser();
  }

  Future<void> _initUser() async {
    setLoading(true);

    // Проверяем текущую сессию
    final currentUser = _authService.currentUser;

    if (currentUser != null) {
      _user = await _authService.getUserData();
    }

    setLoading(false);
    notifyListeners();

    // Подписываемся на изменения состояния аутентификации
    _authService.authStateChanges.listen(_onAuthStateChanged);
  }

  Future<void> _onAuthStateChanged(firebase_auth.User? firebaseUser) async {
    if (firebaseUser == null) {
      _user = null;
      notifyListeners();
      return;
    }

    // Получаем данные пользователя из Firestore
    final userData = await _authService.getUserData();
    _user = userData;
    notifyListeners();
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  Future<bool> signInWithGoogle() async {
    setLoading(true);
    final user = await _authService.signInWithGoogle();
    setLoading(false);

    if (user != null) {
      _user = user;
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> signOut() async {
    setLoading(true);
    await _authService.signOut();
    _user = null;
    setLoading(false);
    notifyListeners();
  }

  Future<bool> updateProfile({String? displayName, String? photoUrl, String? bio}) async {
    setLoading(true);
    final updatedUser = await _authService.updateUserProfile(
      displayName: displayName,
      photoUrl: photoUrl,
      bio: bio,
    );
    setLoading(false);

    if (updatedUser != null) {
      _user = updatedUser;
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> addToFavorites(String recipeId) async {
    final success = await _authService.addToFavorites(recipeId);

    if (success && _user != null) {
      final updatedFavorites = List<String>.from(_user!.favoriteRecipes)..add(recipeId);
      _user = _user!.copyWith(favoriteRecipes: updatedFavorites);
      notifyListeners();
    }

    return success;
  }

  Future<bool> removeFromFavorites(String recipeId) async {
    final success = await _authService.removeFromFavorites(recipeId);

    if (success && _user != null) {
      final updatedFavorites = List<String>.from(_user!.favoriteRecipes)
        ..removeWhere((id) => id == recipeId);
      _user = _user!.copyWith(favoriteRecipes: updatedFavorites);
      notifyListeners();
    }

    return success;
  }

  bool isFavorite(String recipeId) {
    return _user?.favoriteRecipes.contains(recipeId) ?? false;
  }
}
