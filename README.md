

# README.md

```markdown
# Приложение для распознавания ингредиентов и получения рецептов

Это мобильное приложение, которое позволяет:
- Сфотографировать продукты питания
- Распознать ингредиенты и их калорийность с помощью AI
- Получить рецепты на основе распознанных ингредиентов


## Функции

- ✓ Фотографирование ингредиентов с помощью камеры
- ✓ Выбор изображения из галереи
- ✓ Распознавание продуктов на фотографии
- ✓ Определение калорийности каждого ингредиента
- ✓ Генерация рецептов на основе распознанных ингредиентов
- ✓ Расчет калорийности готового блюда
- ✓ Пошаговые инструкции для каждого рецепта

## Установка

1. Клонировать репозиторий
```bash
git clone https://github.com/ВАШ_ПОЛЬЗОВАТЕЛЬ/food-recognition-app.git
```

2. Установить зависимости
```bash
flutter pub get
```

3. Создайте файл `lib/config/api_keys.dart` на основе `api_keys.example.dart` и добавьте свой API ключ OpenAI

4. Запустите приложение
```bash
flutter run
```

## Используемые технологии

- **Flutter** для кросс-платформенной разработки
- **OpenAI GPT-4o** для распознавания изображений и генерации рецептов
- **Camera API** для работы с камерой устройства
- **Image Picker** для выбора изображений из галереи

## Структура проекта

```
lib/
├── config/
│   ├── api_keys.dart
│   └── api_keys.example.dart
├── models/
│   ├── ingredient.dart
│   └── recipe.dart
├── screens/
│   ├── home_screen.dart
│   ├── camera_screen.dart
│   └── results_screen.dart
├── services/
│   ├── openai_service.dart
│   └── image_analyzer.dart
└── main.dart
```

## Требования

- Flutter 2.0 или выше
- Dart 2.12 или выше
- API ключ OpenAI
- Android 5.0+ или iOS 10.0+

## Лицензия

Это приложение распространяется под лицензией MIT. Подробности в файле LICENSE.

## Автор

Разработано с ❤️
```

Вы можете скопировать этот README.md и добавить его в корень вашего проекта. Позже, когда у вас появятся скриншоты приложения, вы можете создать папку "screenshots" в корне репозитория и добавить их туда.

Не забудьте заменить "ВАШ_ПОЛЬЗОВАТЕЛЬ" на ваше имя пользователя GitHub, когда будете клонировать репозиторий.
