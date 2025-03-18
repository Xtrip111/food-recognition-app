class Ingredient {
  final String name;
  final int calories; // калории на 100г

  Ingredient({
    required this.name,
    required this.calories,
  });

  factory Ingredient.fromJson(Map<String, dynamic> json) {
    String name = json['name'] ?? 'Неизвестный ингредиент';

    // Обработка калорийности - может быть числом или строкой
    int calories = 0;
    var calVal = json['calories'];
    if (calVal is int) {
      calories = calVal;
    } else if (calVal is String) {
      calories = int.tryParse(calVal) ?? 0;
    } else if (calVal is double) {
      calories = calVal.toInt();
    }

    return Ingredient(
      name: name,
      calories: calories,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'calories': calories,
    };
  }
}
