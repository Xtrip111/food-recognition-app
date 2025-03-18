class Recipe {
  final String name;
  final List<String> ingredients;
  final String instructions;
  final int calories;

  Recipe({
    required this.name,
    required this.ingredients,
    required this.instructions,
    required this.calories,
  });

  factory Recipe.fromJson(Map<String, dynamic> json) {
    try {
      // Обработка имени
      String name = json['name'] ?? 'Неизвестный рецепт';

      // Обработка ингредиентов
      List<String> ingredients = [];
      if (json['ingredients'] != null) {
        if (json['ingredients'] is List) {
          ingredients = (json['ingredients'] as List)
              .map((item) => item.toString())
              .toList();
        }
      }

      // Обработка инструкций
      String instructions = json['instructions'] ?? 'Инструкция отсутствует';

      // Обработка калорийности
      int calories = 0;
      var calVal = json['calories'];
      if (calVal is int) {
        calories = calVal;
      } else if (calVal is String) {
        calories = int.tryParse(calVal) ?? 0;
      } else if (calVal is double) {
        calories = calVal.toInt();
      }

      return Recipe(
        name: name,
        ingredients: ingredients,
        instructions: instructions,
        calories: calories,
      );
    } catch (e) {
      print('Ошибка при создании рецепта из JSON: $e');
      return Recipe(
        name: 'Ошибка в формате рецепта',
        ingredients: [],
        instructions: 'Не удалось прочитать инструкции',
        calories: 0,
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'ingredients': ingredients,
      'instructions': instructions,
      'calories': calories,
    };
  }
}
