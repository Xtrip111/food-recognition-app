import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../auth/user_provider.dart';
import '../../models/favorite_recipe.dart';
import '../../models/recipe.dart';
import '../auth/login_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({Key? key}) : super(key: key);

  @override
  _FavoritesScreenState createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;
  List<FavoriteRecipe> _favoriteRecipes = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final user = userProvider.user;

      if (user == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final recipesSnapshot = await _firestore
          .collection('favorites')
          .where('userId', isEqualTo: user.id)
          .orderBy('savedAt', descending: true)
          .get();

      final List<FavoriteRecipe> recipes = recipesSnapshot.docs
          .map((doc) => FavoriteRecipe.fromFirestore(doc))
          .toList();

      setState(() {
        _favoriteRecipes = recipes;
        _isLoading = false;
      });
    } catch (e) {
      print('Ошибка загрузки избранного: $e');
      setState(() {
        _error = 'Не удалось загрузить избранные рецепты: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _removeFromFavorites(FavoriteRecipe favoriteRecipe) async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      // Удаляем из Firestore
      await _firestore.collection('favorites').doc(favoriteRecipe.id).delete();

      // Удаляем из списка избранного пользователя
      await userProvider.removeFromFavorites(favoriteRecipe.id);

      // Обновляем локальный список
      setState(() {
        _favoriteRecipes.removeWhere((recipe) => recipe.id == favoriteRecipe.id);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Рецепт удален из избранного')),
        );
      }
    } catch (e) {
      print('Ошибка удаления из избранного: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось удалить рецепт')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);

    if (!userProvider.isLoggedIn) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Избранные рецепты'),
        ),
        body: _buildNotLoggedInView(),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Избранные рецепты'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFavorites,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 60,
              ),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadFavorites,
                child: const Text('Попробовать снова'),
              ),
            ],
          ),
        ),
      );
    }

    if (_favoriteRecipes.isEmpty) {
      return _buildEmptyState();
    }

    return _buildRecipesList();
  }

  Widget _buildNotLoggedInView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_border,
              size: 100,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            const Text(
              'Войдите, чтобы увидеть избранные рецепты',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Сохраняйте ваши любимые рецепты и получайте к ним доступ с любого устройства',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LoginScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              child: const Text(
                'Войти',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bookmark_border,
              size: 100,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            const Text(
              'Нет сохраненных рецептов',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Сохраняйте рецепты, нажимая на кнопку "Добавить в избранное"',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecipesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _favoriteRecipes.length,
      itemBuilder: (context, index) {
        final favoriteRecipe = _favoriteRecipes[index];
        final recipe = favoriteRecipe.recipe;

        return Card(
          elevation: 4,
          margin: const EdgeInsets.only(bottom: 16),
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Заголовок с названием и калорийностью
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                title: Text(
                  recipe.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                subtitle: Text(
                  'Добавлено: ${_formatDate(favoriteRecipe.savedAt)}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getCalorieColor(recipe.calories),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${recipe.calories} ккал',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert),
                      onSelected: (value) {
                        if (value == 'delete') {
                          _removeFromFavorites(favoriteRecipe);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('Удалить из избранного'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Основное содержимое
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ингредиенты:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: recipe.ingredients.take(5).map((ingredient) {
                        return Chip(
                          label: Text(
                            ingredient,
                            style: const TextStyle(fontSize: 12),
                          ),
                          backgroundColor: Colors.green.shade50,
                          labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                        );
                      }).toList(),
                    ),
                    if (recipe.ingredients.length > 5)
                      Text(
                        '+ еще ${recipe.ingredients.length - 5} ингредиентов',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),

              // Кнопка просмотра
              Padding(
                padding: const EdgeInsets.all(16),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: () {
                      _showRecipeDetails(recipe);
                    },
                    child: const Text('Открыть рецепт'),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showRecipeDetails(Recipe recipe) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            // Верхняя полоска для свайпа
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Container(
                height: 5,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            // Заголовок и калории
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      recipe.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _getCalorieColor(recipe.calories),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${recipe.calories} ккал',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Divider(),

            // Содержимое рецепта
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Ингредиенты
                    const Text(
                      'Ингредиенты:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...recipe.ingredients.map((ingredient) => _buildIngredientItem(ingredient)),

                    const SizedBox(height: 24),

                    // Инструкции
                    const Text(
                      'Инструкция:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      recipe.instructions,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIngredientItem(String ingredient) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              ingredient,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Color _getCalorieColor(int calories) {
    if (calories < 300) {
      return Colors.green;
    } else if (calories < 600) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return 'Сегодня';
    } else if (difference.inDays == 1) {
      return 'Вчера';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} дней назад';
    } else {
      return '${dateTime.day}.${dateTime.month}.${dateTime.year}';
    }
  }
}
