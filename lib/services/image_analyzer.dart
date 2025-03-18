import 'dart:io';
import 'dart:convert';
import '../models/recipe.dart';
import '../models/ingredient.dart';
import 'openai_service.dart';

class ImageAnalyzer {
  final OpenAIService _openaiService = OpenAIService();

  Future<List<Ingredient>> identifyIngredients(String imagePath) async {
    try {
      final file = File(imagePath);

      // Запрос к OpenAI GPT-4o для распознавания ингредиентов
      final prompt = '''
Ты эксперт по распознаванию продуктов питания и диетолог.
Внимательно проанализируй это изображение и определи все продукты и ингредиенты, которые на нем видны.
Для каждого ингредиента укажи примерную калорийность на 100 грамм.
Выдай результат в формате JSON:
[
  {"name": "название ингредиента", "calories": число калорий на 100г},
  ...
]
Отвечай только в этом формате, без дополнительного текста. Используй только кириллицу для названий.
''';

      final response = await _openaiService.analyzeImageWithGPT4o(file, prompt);
      print("GPT-4o response: $response"); // Для отладки

      // Извлекаем JSON из ответа
      final jsonStart = response.indexOf('[');
      final jsonEnd = response.lastIndexOf(']') + 1;

      if (jsonStart >= 0 && jsonEnd > jsonStart) {
        final jsonStr = response.substring(jsonStart, jsonEnd);
        print("Extracted JSON: $jsonStr"); // Для отладки

        try {
          final List<dynamic> ingredientsJson = json.decode(jsonStr);
          return ingredientsJson
              .map((json) => Ingredient.fromJson(json))
              .toList();
        } catch (e) {
          print("JSON decode error: $e");
          throw Exception('Ошибка при разборе JSON: $e');
        }
      }

      throw Exception('Не удалось получить корректный JSON из ответа');
    } catch (e) {
      print('Ошибка при распознавании ингредиентов: $e');
      // В случае ошибки возвращаем пустой список
      return [];
    }
  }

  Future<List<Recipe>> getRecipes(List<Ingredient> ingredients) async {
    try {
      // Используем OpenAI для генерации рецептов
      final ingredientsText = ingredients.map((i) => i.name).join(', ');
      final caloriesInfo = ingredients.map((i) => "${i.name}: ${i.calories} ккал/100г").join(', ');

      final prompt = '''
Ты профессиональный шеф-повар и диетолог. Создай 3 разнообразных рецепта блюд, используя некоторые или все из следующих ингредиентов: $ingredientsText.

Информация о калорийности ингредиентов: $caloriesInfo.

Рецепты должны быть реалистичными, вкусными и практичными. Можешь добавить базовые ингредиенты (соль, перец, специи), даже если их нет в списке.

Для каждого рецепта укажи:
1. Название блюда (традиционное или креативное)
2. Полный список необходимых ингредиентов с точными измерениями
3. Подробную пошаговую инструкцию приготовления
4. Точную калорийность готового блюда на порцию (в ккал), рассчитанную на основе ингредиентов и их количества

Выдай результат строго в формате JSON:
[
  {
    "name": "Название блюда",
    "ingredients": ["100г ингредиент 1", "2 шт. ингредиент 2", ...],
    "instructions": "Подробная инструкция по приготовлению...",
    "calories": 123
  },
  ...
]

Важно: используй только кириллицу и отвечай на русском языке.
''';

      final response = await _openaiService.getChatCompletion(prompt);
      print("Recipe response: $response"); // Для отладки

      // Извлекаем JSON из ответа
      final jsonStart = response.indexOf('[');
      final jsonEnd = response.lastIndexOf(']') + 1;

      if (jsonStart >= 0 && jsonEnd > jsonStart) {
        final jsonStr = response.substring(jsonStart, jsonEnd);
        print("Extracted recipe JSON: $jsonStr"); // Для отладки

        try {
          final List<dynamic> recipesJson = json.decode(jsonStr);
          return recipesJson
              .map((json) => Recipe.fromJson(json))
              .toList();
        } catch (e) {
          print("Recipe JSON decode error: $e");
          throw Exception('Ошибка при разборе JSON рецептов: $e');
        }
      }

      throw Exception('Не удалось получить корректный JSON из ответа');
    } catch (e) {
      print('Ошибка при получении рецептов: $e');
      // В случае ошибки возвращаем простой рецепт
      return [
        Recipe(
          name: 'Простое блюдо из имеющихся ингредиентов',
          ingredients: ingredients.map((i) => '1 порция ${i.name}').toList(),
          instructions: 'Смешайте все ингредиенты вместе. Приправьте по вкусу.',
          calories: ingredients.isEmpty ? 0 : ingredients.fold(0, (sum, ingredient) => sum + ingredient.calories ~/ 2),
        ),
      ];
    }
  }
}
