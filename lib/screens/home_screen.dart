import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'camera_screen.dart';
import 'results_screen.dart';

class HomeScreen extends StatelessWidget {
  final List<CameraDescription> cameras;

  const HomeScreen({Key? key, required this.cameras}) : super(key: key);

  Future<void> _pickImageFromGallery(BuildContext context) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null && context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ResultsScreen(
            imagePath: image.path,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // Фоновый градиент
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [
                  Color(0xFFE8F5E9),
                  Colors.white,
                ],
              ),
            ),
          ),

          // Декоративные элементы
          Positioned(
            top: -50,
            right: -30,
            child: Opacity(
              opacity: 0.1,
              child: Image.network(
                'https://cdn-icons-png.flaticon.com/512/1147/1147832.png',
                width: 200,
              ),
            ),
          ),

          Positioned(
            bottom: -50,
            left: -30,
            child: Opacity(
              opacity: 0.1,
              child: Image.network(
                'https://cdn-icons-png.flaticon.com/512/3823/3823396.png',
                width: 200,
              ),
            ),
          ),

          // Основной контент
          SafeArea(
            child: Column(
              children: [
                // Верхняя часть с логотипом и заголовком
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
                  child: Column(
                    children: [
                      // Логотип приложения
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withOpacity(0.2),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.restaurant,
                          size: 60,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Название приложения
                      Text(
                        'Кулинарный AI',
                        style: Theme.of(context).textTheme.displayLarge,
                      ),

                      const SizedBox(height: 12),

                      // Подзаголовок
                      Text(
                        'Готовьте вкусные блюда из продуктов, которые у вас уже есть',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Основной блок с объяснением функций
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Card(
                    elevation: 8,
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          // Заголовок карточки
                          Text(
                            'Как это работает',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),

                          const SizedBox(height: 16),

                          // Шаги работы приложения
                          _buildStep(
                            context,
                            '1',
                            'Сфотографируйте ингредиенты',
                            Icons.camera_alt_outlined,
                          ),

                          const SizedBox(height: 16),

                          _buildStep(
                            context,
                            '2',
                            'AI распознает продукты и их калорийность',
                            Icons.psychology_outlined,
                          ),

                          const SizedBox(height: 16),

                          _buildStep(
                            context,
                            '3',
                            'Получите рецепты на основе ваших ингредиентов',
                            Icons.restaurant_menu_outlined,
                          ),

                          const SizedBox(height: 24),

                          // Кнопки действий
                          Row(
                            children: [
                              // Кнопка фото с камеры
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    if (cameras.isEmpty) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Камера недоступна')),
                                      );
                                      return;
                                    }
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => CameraScreen(cameras: cameras),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.camera_alt),
                                  label: const Text('Камера'),
                                ),
                              ),

                              const SizedBox(width: 16),

                              // Кнопка выбора из галереи
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => _pickImageFromGallery(context),
                                  icon: const Icon(Icons.photo_library),
                                  label: const Text('Галерея'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const Spacer(),

                // Нижняя часть с текстом о приватности
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Ваши фотографии обрабатываются с соблюдением конфиденциальности',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Виджет для отображения шагов работы приложения
  Widget _buildStep(BuildContext context, String stepNumber, String text, IconData icon) {
    return Row(
      children: [
        // Номер шага
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              stepNumber,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),

        const SizedBox(width: 16),

        // Иконка
        Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
        ),

        const SizedBox(width: 12),

        // Текст шага
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}
