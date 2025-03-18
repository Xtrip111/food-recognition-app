import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'results_screen.dart';

class CameraScreen extends StatefulWidget {
  final List<CameraDescription> cameras;

  const CameraScreen({Key? key, required this.cameras}) : super(key: key);

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> with WidgetsBindingObserver {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  bool _isCameraReady = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _controller;

    // Приложение находится в неактивном состоянии
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    if (widget.cameras.isEmpty) {
      print('Нет доступных камер!');
      return;
    }

    // Выбираем первую доступную камеру
    final camera = widget.cameras.first;

    // Инициализируем контроллер камеры
    final controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
    );

    _controller = controller;

    // Инициализируем контроллер
    _initializeControllerFuture = controller.initialize().then((_) {
      if (!mounted) return;
      setState(() {
        _isCameraReady = true;
      });
    }).catchError((error) {
      print('Ошибка инициализации камеры: $error');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Сделайте фото')),
      body: _controller == null
          ? const Center(child: Text('Инициализация камеры...'))
          : FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Ошибка инициализации камеры: ${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              );
            }

            return Stack(
              alignment: Alignment.center,
              children: [
                CameraPreview(_controller!),
                Positioned(
                  bottom: 20,
                  child: Container(
                    padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Расположите ингредиенты в кадре',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: _isCameraReady
          ? FloatingActionButton(
        backgroundColor: Colors.green,
        child: const Icon(Icons.camera_alt),
        onPressed: () async {
          try {
            // Ждем инициализации камеры
            await _initializeControllerFuture;

            // Делаем снимок
            final image = await _controller!.takePicture();

            // Переходим на экран результатов
            if (!mounted) return;

            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => ResultsScreen(
                  imagePath: image.path,
                ),
              ),
            );
          } catch (e) {
            print('Ошибка при съемке фото: $e');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Ошибка: $e')),
            );
          }
        },
      )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
