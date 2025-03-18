import 'package:flutter/material.dart';
import 'dart:io';
import '../services/image_analyzer.dart';
import '../models/recipe.dart';
import '../models/ingredient.dart';

class ResultsScreen extends StatefulWidget {
  final String imagePath;

  const ResultsScreen({Key? key, required this.imagePath}) : super(key: key);

  @override
  _ResultsScreenState createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  bool _isLoading = true;
  List<Recipe> _recipes = [];
  List<Ingredient> _ingredients = [];
  String _error = '';
  int _selectedRecipeIndex = 0;

  @override
  void initState() {
    super.initState();
    _analyzeImage();
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
      appBar: AppBar(
        title: const Text('Результаты'),
        backgroundColor: Colors.green,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
            ),
            const SizedBox(height: 20),
            Text(
              _ingredients.isEmpty
                  ? 'Анализируем ингредиенты...'
                  : 'Ищем рецепты для: ${_ingredients.map((i) => i.name).join(", ")}...',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      );
    }

    if (_error.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 60,
              ),
              const SizedBox(height: 20),
              Text(
                _error,
                style: const TextStyle(color: Colors.red, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
                child: const Text('Вернуться назад'),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Отображаем фото
          Stack(
            alignment: Alignment.bottomCenter,
            children: [
              Image.file(
                File(widget.imagePath),
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
              ),
              Container(
                width: double.infinity,
                color: Colors.black54,
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'Распознано ${_ingredients.length} ингредиентов',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          // Распознанные ингредиенты
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Распознанные ингредиенты:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _ingredients
                      .map((ingredient) => Chip(
                    label: Text('${ingredient.name} (${ingredient.calories} ккал/100г)'),
                    backgroundColor: Colors.green[100],
                  ))
                      .toList(),
                ),
                const SizedBox(height: 8),
                Text(
                  'Общая калорийность всех ингредиентов: ${_calculateTotalCalories()} ккал/100г',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),

          // Список рецептов
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Возможные рецепты:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${_recipes.length} найдено',
                  style: TextStyle(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),

          if (_recipes.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(
                child: Text(
                  'Рецептов не найдено. Попробуйте другие ингредиенты.',
                  style: TextStyle(fontStyle: FontStyle.italic),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            Column(
              children: [
                // Вкладки с рецептами
                SizedBox(
                  height: 60,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _recipes.length,
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedRecipeIndex = index;
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.only(right: 10, top: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            color: _selectedRecipeIndex == index
                                ? Colors.green
                                : Colors.grey[200],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Center(
                            child: Text(
                              _recipes[index].name,
                              style: TextStyle(
                                color: _selectedRecipeIndex == index
                                    ? Colors.white
                                    : Colors.black,
                                fontWeight: _selectedRecipeIndex == index
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Детали выбранного рецепта
                if (_recipes.isNotEmpty)
                  _buildRecipeDetails(_recipes[_selectedRecipeIndex]),
              ],
            ),
        ],
      ),
    );
  }

  int _calculateTotalCalories() {
    return _ingredients.fold(0, (sum, ingredient) => sum + ingredient.calories);
  }

  Widget _buildRecipeDetails(Recipe recipe) {
    return Card(
      margin: const EdgeInsets.all(16.0),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getCalorieColor(recipe.calories),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${recipe.calories} ккал',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 30),
            const Text(
              'Ингредиенты:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...recipe.ingredients.map(
                  (ingredient) => Padding(
                padding: const EdgeInsets.only(bottom: 6.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(fontSize: 16)),
                    Expanded(
                      child: Text(
                        ingredient,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Инструкция:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              recipe.instructions,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            const Text(
              'Примечание:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Калорийность указана на порцию. Точное значение может варьироваться в зависимости от размера порций и способа приготовления.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
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
}
