import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'screens/home_screen.dart';

List<CameraDescription> cameras = [];

Future<void> main() async {
  // Убедимся, что Flutter инициализирован
  WidgetsFlutterBinding.ensureInitialized();

  // Устанавливаем предпочтительную ориентацию
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Устанавливаем стиль статус-бара
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Получаем список доступных камер
  try {
    cameras = await availableCameras();
  } on CameraException catch (e) {
    print('Ошибка при получении камер: ${e.description}');
  }

  runApp(const FoodRecognitionApp());
}

class FoodRecognitionApp extends StatelessWidget {
  const FoodRecognitionApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Распознавание Ингредиентов',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF4CAF50),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4CAF50),
          primary: const Color(0xFF4CAF50),
          secondary: const Color(0xFFFF9800),
          surface: Colors.white,
          background: Colors.white,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'Montserrat',
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2E7D32),
          ),
          displayMedium: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2E7D32),
          ),
          titleLarge: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2E7D32),
          ),
          titleMedium: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            color: Colors.black87,
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            color: Colors.black87,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4CAF50),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 4,
            shadowColor: const Color(0xFF4CAF50).withOpacity(0.4),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF4CAF50),
            side: const BorderSide(color: Color(0xFF4CAF50), width: 2),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF2E7D32),
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: 'Montserrat',
            color: Color(0xFF2E7D32),
          ),
          iconTheme: IconThemeData(
            color: Color(0xFF2E7D32),
          ),
        ),
        cardTheme: CardTheme(
          elevation: 6,
          shadowColor: Colors.black.withOpacity(0.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          clipBehavior: Clip.antiAlias,
        ),
      ),
      home: HomeScreen(cameras: cameras),
    );
  }
}
