import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'results_screen.dart';
import 'dart:math' as math;

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
  bool _isFlashOn = false;
  double _minAvailableZoom = 1.0;
  double _maxAvailableZoom = 1.0;
  double _currentZoom = 1.0;
  bool _isGridVisible = false;
  bool _showFocusCircle = false;
  Offset _focusPoint = Offset.zero;

  // Для анимации
  final List<Alignment> _ingredientPositions = [
    const Alignment(-0.8, -0.5),
    const Alignment(0.8, -0.7),
    const Alignment(0.5, 0.8),
    const Alignment(-0.6, 0.6),
  ];

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

    // Выбираем заднюю камеру
    final camera = widget.cameras.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.back,
      orElse: () => widget.cameras.first,
    );

    // Инициализируем контроллер камеры
    final controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    _controller = controller;

    // Инициализируем контроллер
    _initializeControllerFuture = controller.initialize().then((_) async {
      if (!mounted) return;

      // Получаем диапазон зума
      await controller.getMaxZoomLevel().then((value) => _maxAvailableZoom = value);
      await controller.getMinZoomLevel().then((value) => _minAvailableZoom = value);

      setState(() {
        _isCameraReady = true;
      });
    }).catchError((error) {
      print('Ошибка инициализации камеры: $error');
    });
  }

  Future<void> _toggleFlash() async {
    if (_controller == null) return;

    try {
      if (_isFlashOn) {
        await _controller!.setFlashMode(FlashMode.off);
      } else {
        await _controller!.setFlashMode(FlashMode.torch);
      }

      setState(() {
        _isFlashOn = !_isFlashOn;
      });
    } catch (e) {
      print('Ошибка при переключении вспышки: $e');
    }
  }

  Future<void> _setZoom(double zoom) async {
    if (_controller == null) return;

    try {
      await _controller!.setZoomLevel(zoom);
      setState(() {
        _currentZoom = zoom;
      });
    } catch (e) {
      print('Ошибка при установке зума: $e');
    }
  }

  void _onTapToFocus(TapUpDetails details) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return;
    }

    final screenSize = MediaQuery.of(context).size;
    final double x = details.localPosition.dx / screenSize.width;
    final double y = details.localPosition.dy / screenSize.height;

    setState(() {
      _showFocusCircle = true;
      _focusPoint = details.localPosition;
    });

    _controller!.setFocusPoint(Offset(x, y));
    _controller!.setExposurePoint(Offset(x, y));

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _showFocusCircle = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Предпросмотр камеры
          FutureBuilder<void>(
            future: _initializeControllerFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 80,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Ошибка инициализации камеры: ${snapshot.error}',
                            style: const TextStyle(color: Colors.white),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: const Text('Вернуться назад'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return GestureDetector(
                  onTapUp: _onTapToFocus,
                  child: Stack(
                    children: [
                      // Предпросмотр камеры
                      SizedBox.expand(
                        child: FittedBox(
                          fit: BoxFit.cover,
                          child: SizedBox(
                            width: _controller!.value.previewSize!.height,
                            height: _controller!.value.previewSize!.width,
                            child: CameraPreview(_controller!),
                          ),
                        ),
                      ),

                      // Сетка (если включена)
                      if (_isGridVisible)
                        _buildGrid(),

                      // Декоративные анимации для ингредиентов
                      ..._buildIngredientAnimations(),

                      // Круг фокусировки
                      if (_showFocusCircle)
                        Positioned(
                          left: _focusPoint.dx - 25,
                          top: _focusPoint.dy - 25,
                          child: Container(
                            height: 50,
                            width: 50,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 1.5),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.center_focus_strong,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              } else {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(
                        color: Colors.white,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Подготовка камеры...',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                );
              }
            },
          ),

          // Верхняя панель с кнопкой возврата и настройками
          SafeArea(
            child: Column(
              children: [
                // Верхняя панель
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Кнопка возврата
                      Container(
                        decoration: const BoxDecoration(
                          color: Colors.black38,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),

                      // Текст подсказка
                      Expanded(
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black38,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Text(
                              'Расположите ингредиенты в кадре',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Кнопка настроек/сетки
                      Container(
                        decoration: const BoxDecoration(
                          color: Colors.black38,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: Icon(
                            _isGridVisible ? Icons.grid_off : Icons.grid_on,
                            color: Colors.white,
                          ),
                          onPressed: () {
                            setState(() {
                              _isGridVisible = !_isGridVisible;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Нижняя панель с элементами управления
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Кнопка вспышки
                      Container(
                        decoration: BoxDecoration(
                          color: _isFlashOn ? Colors.amber : Colors.black38,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.5),
                            width: 2,
                          ),
                        ),
                        child: IconButton(
                          icon: Icon(
                            _isFlashOn ? Icons.flash_on : Icons.flash_off,
                            color: Colors.white,
                          ),
                          onPressed: _toggleFlash,
                        ),
                      ),

                      // Кнопка съемки
                      GestureDetector(
                        onTap: () async {
                          try {
                            // Показываем анимацию затвора
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Обработка фото...'),
                                duration: Duration(seconds: 1),
                              ),
                            );

                            await _initializeControllerFuture;
                            final image = await _controller!.takePicture();

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
                          }
                        },
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 4,
                            ),
                          ),
                          child: Container(
                            margin: const EdgeInsets.all(12),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),

                      // Слайдер зума
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black38,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.zoom_out,
                              color: Colors.white,
                              size: 20,
                            ),
                            SizedBox(
                              width: 100,
                              child: Slider(
                                value: _currentZoom,
                                min: _minAvailableZoom,
                                max: _maxAvailableZoom,
                                activeColor: Colors.white,
                                inactiveColor: Colors.white30,
                                onChanged: (value) {
                                  _setZoom(value);
                                },
                              ),
                            ),
                            const Icon(
                              Icons.zoom_in,
                              color: Colors.white,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white30),
      ),
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(child: Container(decoration: BoxDecoration(border: Border.all(color: Colors.white30)))),
                Expanded(child: Container(decoration: BoxDecoration(border: Border.all(color: Colors.white30)))),
                Expanded(child: Container(decoration: BoxDecoration(border: Border.all(color: Colors.white30)))),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(child: Container(decoration: BoxDecoration(border: Border.all(color: Colors.white30)))),
                Expanded(child: Container(decoration: BoxDecoration(border: Border.all(color: Colors.white30)))),
                Expanded(child: Container(decoration: BoxDecoration(border: Border.all(color: Colors.white30)))),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(child: Container(decoration: BoxDecoration(border: Border.all(color: Colors.white30)))),
                Expanded(child: Container(decoration: BoxDecoration(border: Border.all(color: Colors.white30)))),
                Expanded(child: Container(decoration: BoxDecoration(border: Border.all(color: Colors.white30)))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildIngredientAnimations() {
    final icons = [
      Icons.restaurant,
      Icons.set_meal,
      Icons.local_pizza,
      Icons.cake,
    ];

    return List.generate(
      4,
          (index) => Positioned.fill(
        child: Align(
          alignment: _ingredientPositions[index],
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icons[index],
              color: Colors.white.withOpacity(0.7),
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}
