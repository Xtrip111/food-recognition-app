import 'package:flutter/material.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import '../services/image_analyzer.dart';
import '../models/recipe.dart';
import '../models/ingredient.dart';
import '../auth/user_provider.dart';
import '../services/favorites_service.dart';
import '../screens/auth/login_screen.dart';

class ResultsScreen extends StatefulWidget {
  final String imagePath;

  const ResultsScreen({Key? key, required this.imagePath}) : super(key: key);

  @override
  _ResultsScreenState createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> with TickerProviderStateMixin {
  bool _isLoading = true;
  List<Recipe> _recipes = [];
  List<Ingredient> _ingredients = [];
  String _error = '';
  int _selectedRecipeIndex = 0;
  int _selectedTabIndex = 0; // 0 - ингредиенты, 1 - инструкции

  // Контроллеры анимации
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // Настраиваем анимации
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutQuart,
    ));

    _analyzeImage();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _analyzeImage() async {
    try {
      setState(() {
        _isLoading = true;
        _error = '';
      });

      // Анализируем изображение
      final analyzer = ImageAnalyzer();

      // Показываем сообщение о распознавании ингредиентов
      setState(() {
        _isLoading = true;
        _error = '';
      });

      final ingredients = await analyzer.identifyIngredients(widget.imagePath);

      if (ingredients.isEmpty) {
        setState(() {
          _error = 'Не удалось распознать ингредиенты на изображении. Попробуйте сделать более четкое фото.';
          _isLoading = false;
        });
        return;
      }

      // Показываем сообщение о поиске рецептов
      setState(() {
        _ingredients = ingredients;
      });

      // Получаем рецепты на основе ингредиентов
      final recipes = await analyzer.getRecipes(ingredients);

      setState(() {
        _recipes = recipes;
        _isLoading = false;
      });

      // Запускаем анимации
      _fadeController.forward();
      _slideController.forward();
    } catch (e) {
      setState(() {
        _error = 'Произошла ошибка при анализе изображения: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return _buildLoadingScreen();
    }

    if (_error.isNotEmpty) {
      return _buildErrorScreen();
    }

    return _buildResultsScreen();
  }

  Widget _buildLoadingScreen() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF388E3C), Color(0xFF4CAF50)],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Верхняя часть с возвратом
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ),
          ),

          const Spacer(),

          // Анимация загрузки
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Изображение пищи
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    image: DecorationImage(
                      image: FileImage(File(widget.imagePath)),
                      fit: BoxFit.cover,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // Анимированный индикатор загрузки
                SizedBox(
                  width: 180,
                  child: _ingredients.isEmpty
                      ? _buildAnalyzingAnimation("Распознаем ингредиенты")
                      : _buildAnalyzingAnimation("Ищем лучшие рецепты"),
                ),

                const SizedBox(height: 80),

                if (_ingredients.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: Card(
                        elevation: 0,
                        color: Colors.white.withOpacity(0.2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.check_circle, color: Colors.white),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Найдено ${_ingredients.length} ингредиентов',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _ingredients
                                    .take(5)
                                    .map((ingredient) => Chip(
                                  label: Text(ingredient.name),
                                  backgroundColor: Colors.white,
                                  labelStyle: const TextStyle(
                                    color: Color(0xFF388E3C),
                                  ),
                                ))
                                    .toList(),
                              ),
                              if (_ingredients.length > 5)
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    '+ еще ${_ingredients.length - 5}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const Spacer(flex: 2),
        ],
      ),
    );
  }

  Widget _buildAnalyzingAnimation(String text) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.3),
            borderRadius: BorderRadius.circular(2),
          ),
          child: LinearProgressIndicator(
            backgroundColor: Colors.transparent,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white.withOpacity(0.8)),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildErrorScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Верхняя часть с возвратом
            SafeArea(
              child: Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ),

            const Spacer(),

            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 80,
            ),
            const SizedBox(height: 24),
            Text(
              'Что-то пошло не так',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              _error,
              style: const TextStyle(color: Colors.red, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.arrow_back),
              label: const Text('Назад'),
            ),

            const Spacer(flex: 2),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsScreen() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: CustomScrollView(
        slivers: [
          // Плавающий аппбар с фото и ингредиентами
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            backgroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: _buildImageHeader(),
            ),
            title: AnimatedOpacity(
              opacity: 1.0,
              duration: const Duration(milliseconds: 300),
              child: const Text(
                'Ваши рецепты',
                style: TextStyle(
                  color: Color(0xFF2E7D32),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.share, color: Color(0xFF2E7D32)),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Функция поделиться скоро появится')),
                  );
                },
              ),
            ],
          ),

          // Секция с ингредиентами и калорийностью
          SliverToBoxAdapter(
            child: SlideTransition(
              position: _slideAnimation,
              child: _buildIngredientsSection(),
            ),
          ),

          // Заголовок рецептов
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Text(
                'Рецепты (${_recipes.length})',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32),
                ),
              ),
            ),
          ),

          // Вкладки рецептов (горизонтальная прокрутка)
          SliverToBoxAdapter(
            child: SizedBox(
              height: 60,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _recipes.length,
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                itemBuilder: (context, index) {
                  return _buildRecipeTab(index);
                },
              ),
            ),
          ),

          // Выбранный рецепт
          if (_recipes.isNotEmpty)
            SliverToBoxAdapter(
              child: _buildSelectedRecipe(),
            ),

          // Нижний отступ
          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),
        ],
      ),
    );
  }

  Widget _buildImageHeader() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Фото продуктов с затемнением
        ShaderMask(
          shaderCallback: (rect) {
            return LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.black, Colors.transparent],
            ).createShader(Rect.fromLTRB(0, 0, rect.width, rect.height));
          },
          blendMode: BlendMode.dstIn,
          child: Image.file(
            File(widget.imagePath),
            fit: BoxFit.cover,
          ),
        ),

        // Декоративный оверлей
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.3),
                Colors.transparent,
              ],
            ),
          ),
        ),

        // Иконки ингредиентов (декоративные)
        Positioned(
          top: 100,
          left: 20,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.restaurant,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),

        Positioned(
          top: 70,
          right: 40,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.local_pizza,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),

        // Статус с количеством ингредиентов
        Positioned(
          bottom: 20,
          left: 20,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50).withOpacity(0.8),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  '${_ingredients.length} ингредиентов распознано',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIngredientsSection() {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Найденные ингредиенты',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                Text(
                  'Всего: ${_calculateTotalCalories()} ккал/100г',
                  style: TextStyle(
                    color: _getCalorieColor(_calculateTotalCalories()),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildIngredientsGrid(),
          ],
        ),
      ),
    );
  }

  Widget _buildIngredientsGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.8,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: _ingredients.length,
      itemBuilder: (context, index) {
        final ingredient = _ingredients[index];
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: _getIngredientBackgroundColor(ingredient.calories),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    _getIngredientIcon(ingredient.name),
                    color: _getIngredientIconColor(ingredient.calories),
                    size: 14,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      ingredient.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${ingredient.calories} ккал/100г',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRecipeTab(int index) {
    final bool isSelected = _selectedRecipeIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedRecipeIndex = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(right: 10, top: 10, bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4CAF50) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: const Color(0xFF4CAF50).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ]
              : [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            _recipes[index].name,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black87,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedRecipe() {
    final recipe = _recipes[_selectedRecipeIndex];
    final userProvider = Provider.of<UserProvider>(context);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Верхняя часть карточки с заголовком и калориями
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withOpacity(0.1),
              ),
              child: Row(
                children: [
                  const Icon(Icons.restaurant_menu, color: Color(0xFF4CAF50)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          recipe.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Время приготовления: ~30 минут',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getCalorieColor(recipe.calories),
                      borderRadius: BorderRadius.circular(20),
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

            // Вкладки для переключения между ингредиентами и инструкциями
            _buildRecipeTabBar(),

            // Контент в зависимости от выбранной вкладки
            _selectedTabIndex == 0
                ? _buildIngredientsTab(recipe)
                : _buildInstructionsTab(recipe),

            // Кнопка "Добавить в избранное"
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: _buildFavoriteButton(recipe),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecipeTabBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildTabButton('Ингредиенты', 0, Icons.list),
          _buildTabButton('Инструкция', 1, Icons.menu_book),
        ],
      ),
    );
  }

  Widget _buildTabButton(String title, int index, IconData icon) {
    final bool isActive = _selectedTabIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTabIndex = index;
          });
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF4CAF50).withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isActive ? const Color(0xFF4CAF50) : Colors.grey[300]!,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isActive ? const Color(0xFF4CAF50) : Colors.grey[600],
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: isActive ? const Color(0xFF4CAF50) : Colors.grey[600],
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIngredientsTab(Recipe recipe) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ингредиенты:',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...recipe.ingredients.map((ingredient) => _buildIngredientItem(ingredient)),
        ],
      ),
    );
  }

  Widget _buildInstructionsTab(Recipe recipe) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Инструкция:',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildInstructions(recipe.instructions),
        ],
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
              color: Color(0xFF4CAF50),
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

  Widget _buildInstructions(String instructions) {
    // Разбиваем инструкцию на шаги (предполагаем, что шаги разделены точкой)
    final steps = instructions.split('.')
        .where((step) => step.trim().isNotEmpty)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(
        steps.length,
            (index) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: Color(0xFF4CAF50),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${steps[index].trim()}.',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFavoriteButton(Recipe recipe) {
    final userProvider = Provider.of<UserProvider>(context);
    final String recipeId = recipe.name; // Используем имя рецепта как ID

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _toggleFavorite(recipe),
        icon: Icon(
          userProvider.isFavorite(recipeId)
              ? Icons.favorite
              : Icons.favorite_border,
        ),
        label: Text(
          userProvider.isFavorite(recipeId)
              ? 'В избранном'
              : 'Добавить в избранное',
        ),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          backgroundColor: userProvider.isFavorite(recipeId)
              ? Colors.pink
              : Colors.green,
        ),
      ),
    );
  }

  Future<void> _toggleFavorite(Recipe recipe) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    if (!userProvider.isLoggedIn) {
      // Показываем диалог с предложением войти
      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Требуется авторизация'),
          content: const Text(
            'Для сохранения рецепта в избранное необходимо войти в аккаунт. Хотите войти сейчас?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              },
              child: const Text('Войти'),
            ),
          ],
        ),
      );
      return;
    }

    final recipeId = recipe.name; // Используем имя рецепта как ID
    final isInFavorites = userProvider.isFavorite(recipeId);
    final favoritesService = FavoritesService();

    if (isInFavorites) {
      // Удаляем из избранного
      await userProvider.removeFromFavorites(recipeId);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Рецепт удален из избранного')),
      );
    } else {
      // Добавляем в избранное
      final success = await userProvider.addToFavorites(recipeId);

      if (success) {
        // Сохраняем в Firestore
        await favoritesService.addToFavorites(recipe, widget.imagePath);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Рецепт добавлен в избранное')),
        );
      }
    }
  }

  int _calculateTotalCalories() {
    return _ingredients.fold(0, (sum, ingredient) => sum + ingredient.calories);
  }

  Color _getCalorieColor(int calories) {
    if (calories < 300) {
      return const Color(0xFF4CAF50); // Зеленый для низкой калорийности
    } else if (calories < 600) {
      return const Color(0xFFFF9800); // Оранжевый для средней
    } else {
      return const Color(0xFFF44336); // Красный для высокой
    }
  }

  Color _getIngredientBackgroundColor(int calories) {
    if (calories < 100) {
      return const Color(0xFFE8F5E9); // Светло-зеленый
    } else if (calories < 200) {
      return const Color(0xFFFFF3E0); // Светло-оранжевый
    } else {
      return const Color(0xFFFFEBEE); // Светло-красный
    }
  }

  Color _getIngredientIconColor(int calories) {
    if (calories < 100) {
      return const Color(0xFF4CAF50); // Зеленый
    } else if (calories < 200) {
      return const Color(0xFFFF9800); // Оранжевый
    } else {
      return const Color(0xFFF44336); // Красный
    }
  }

  IconData _getIngredientIcon(String name) {
    // Определяем иконку на основе названия ингредиента
    final lowercaseName = name.toLowerCase();

    if (lowercaseName.contains('мяс') ||
        lowercaseName.contains('говядин') ||
        lowercaseName.contains('свинин')) {
      return Icons.restaurant_menu;
    } else if (lowercaseName.contains('рыб') ||
        lowercaseName.contains('лосос') ||
        lowercaseName.contains('треск')) {
      return Icons.set_meal;
    } else if (lowercaseName.contains('молок') ||
        lowercaseName.contains('сыр') ||
        lowercaseName.contains('творог')) {
      return Icons.water_drop;
    } else if (lowercaseName.contains('яблок') ||
        lowercaseName.contains('груш') ||
        lowercaseName.contains('фрукт')) {
      return Icons.apple;
    } else if (lowercaseName.contains('морков') ||
        lowercaseName.contains('капуст') ||
        lowercaseName.contains('овощ')) {
      return Icons.eco;
    } else if (lowercaseName.contains('мука') ||
        lowercaseName.contains('хлеб') ||
        lowercaseName.contains('тест')) {
      return Icons.bakery_dining;
    } else if (lowercaseName.contains('масл') ||
        lowercaseName.contains('соус') ||
        lowercaseName.contains('майонез')) {
      return Icons.opacity;
    }

    return Icons.restaurant;
  }
}
