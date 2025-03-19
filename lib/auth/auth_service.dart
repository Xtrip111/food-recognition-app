import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/app_user.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Получение текущего состояния пользователя
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Получение текущего пользователя
  User? get currentUser => _auth.currentUser;

  // Вход через Google
  Future<AppUser?> signInWithGoogle() async {
    try {
      // Запуск процесса входа в Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      // Получение данных аутентификации
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Создание учетных данных Firebase
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Вход в Firebase
      final UserCredential authResult = await _auth.signInWithCredential(credential);
      final User? user = authResult.user;

      if (user == null) return null;

      // Сохранение или обновление данных пользователя в Firestore
      final appUser = await _saveUserToFirestore(user);
      return appUser;
    } catch (e) {
      print('Ошибка входа через Google: $e');
      return null;
    }
  }

  // Сохранение данных пользователя в Firestore
  Future<AppUser> _saveUserToFirestore(User user) async {
    DocumentReference userRef = _firestore.collection('users').doc(user.uid);

    // Проверяем, существует ли пользователь
    final userDoc = await userRef.get();

    final AppUser appUser;

    if (userDoc.exists) {
      // Обновляем существующего пользователя
      await userRef.update({
        'lastLogin': FieldValue.serverTimestamp(),
        'email': user.email ?? '',
        'displayName': user.displayName ?? '',
        'photoUrl': user.photoURL,
      });

      final updatedUserDoc = await userRef.get();
      appUser = AppUser.fromJson({
        'id': user.uid,
        ...updatedUserDoc.data() as Map<String, dynamic>,
      });
    } else {
      // Создаем нового пользователя
      final newUser = AppUser(
        id: user.uid,
        email: user.email ?? '',
        displayName: user.displayName ?? 'Пользователь',
        photoUrl: user.photoURL,
        createdAt: DateTime.now(),
        lastLogin: DateTime.now(),
      );

      await userRef.set(newUser.toJson());
      appUser = newUser;
    }

    return appUser;
  }

  // Получение данных пользователя из Firestore
  Future<AppUser?> getUserData() async {
    try {
      if (currentUser == null) return null;

      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .get();

      if (userDoc.exists) {
        return AppUser.fromJson({
          'id': currentUser!.uid,
          ...userDoc.data() as Map<String, dynamic>,
        });
      }

      return null;
    } catch (e) {
      print('Ошибка получения данных пользователя: $e');
      return null;
    }
  }

  // Обновление данных пользователя
  Future<AppUser?> updateUserProfile({
    String? displayName,
    String? photoUrl,
    String? bio,
  }) async {
    try {
      if (currentUser == null) return null;

      final updates = <String, dynamic>{};
      if (displayName != null) updates['displayName'] = displayName;
      if (photoUrl != null) updates['photoUrl'] = photoUrl;
      if (bio != null) updates['bio'] = bio;

      await _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .update(updates);

      return getUserData();
    } catch (e) {
      print('Ошибка обновления профиля: $e');
      return null;
    }
  }

  // Добавление рецепта в избранное
  Future<bool> addToFavorites(String recipeId) async {
    try {
      if (currentUser == null) return false;

      await _firestore.collection('users').doc(currentUser!.uid).update({
        'favoriteRecipes': FieldValue.arrayUnion([recipeId]),
      });

      return true;
    } catch (e) {
      print('Ошибка добавления в избранное: $e');
      return false;
    }
  }

  // Удаление рецепта из избранного
  Future<bool> removeFromFavorites(String recipeId) async {
    try {
      if (currentUser == null) return false;

      await _firestore.collection('users').doc(currentUser!.uid).update({
        'favoriteRecipes': FieldValue.arrayRemove([recipeId]),
      });

      return true;
    } catch (e) {
      print('Ошибка удаления из избранного: $e');
      return false;
    }
  }

  // Выход из аккаунта
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      print('Ошибка выхода из аккаунта: $e');
    }
  }
}
