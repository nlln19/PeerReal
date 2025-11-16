import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  List<CameraDescription> _cameras = [];
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;

  bool _initializing = true;
  String? _errorMessage;

  // BeReal-Flow
  int _step = 1; // 1 = Hauptbild, 2 = Selfie
  Uint8List? _mainImage;

  @override
  void initState() {
    super.initState();
    _setupCamerasAndInit();
  }

  Future<void> _setupCamerasAndInit() async {
    setState(() {
      _initializing = true;
      _errorMessage = null;
    });

    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        setState(() {
          _errorMessage = 'Keine Kamera gefunden.';
          _initializing = false;
        });
        return;
      }

      await _initForStep1();
    } catch (e) {
      print('❌ Fehler bei Kamera-Setup: $e');
      if (!mounted) return;
      setState(() {
        _errorMessage =
            'Kamera konnte nicht gestartet werden.\nFehler: $e';
        _initializing = false;
      });
    }
  }

  Future<void> _initForStep1() async {
    // Versuch: "Back" / externe Kamera, sonst erste
    final CameraDescription camera = _cameras.first;
    await _initController(camera);
    if (!mounted) return;
    setState(() {
      _step = 1;
      _initializing = false;
    });
  }

  Future<void> _initForStep2() async {
    // Versuch: Frontkamera, sonst gleiche wie Schritt 1
    CameraDescription camera;
    try {
      camera = _cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras.first,
      );
    } catch (_) {
      camera = _cameras.first;
    }

    await _initController(camera);
    if (!mounted) return;
    setState(() {
      _step = 2;
      _initializing = false;
    });
  }

  Future<void> _initController(CameraDescription camera) async {
    _controller?.dispose();

    final controller = CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    final initializeFuture = controller.initialize();
    setState(() {
      _controller = controller;
      _initializeControllerFuture = initializeFuture;
    });

    await initializeFuture;
  }

  Future<void> _onCapturePressed() async {
    final controller = _controller;
    if (controller == null) return;

    try {
      await _initializeControllerFuture;

      final XFile file = await controller.takePicture();
      final bytes = await file.readAsBytes();
      print('📸 Step $_step captured ${bytes.length} bytes');

      if (!mounted) return;

      if (_step == 1) {
        // Hauptbild fertig → Step 2 (Selfie)
        setState(() {
          _mainImage = bytes;
          _initializing = true;
        });
        await _initForStep2();
      } else {
        // Selfie fertig → beide Bilder zurück
        if (_mainImage == null) {
          // Fallback: nur Selfie zurück
          Navigator.pop(context, {'main': bytes, 'selfie': bytes});
        } else {
          Navigator.pop(context, {'main': _mainImage!, 'selfie': bytes});
        }
      }
    } catch (e) {
      print('❌ Fehler beim Foto machen: $e');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: const Color(0xFF05050A),
        appBar: AppBar(
          title: const Text('Webcam'),
          backgroundColor: const Color(0xFF05050A),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.videocam_off,
                    color: Colors.white54, size: 48),
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _setupCamerasAndInit,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Erneut versuchen'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_initializing || _controller == null || _initializeControllerFuture == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF05050A),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final controller = _controller!;
    final isStep1 = _step == 1;

    return Scaffold(
      backgroundColor: const Color(0xFF05050A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF05050A),
        title: Text(isStep1 ? 'Moment aufnehmen' : 'Selfie aufnehmen'),
      ),
      body: Column(
        children: [
          // Preview + kleines Overlay mit erstem Bild (wenn schon gemacht)
          Expanded(
            child: FutureBuilder(
              future: _initializeControllerFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }

                final size = controller.value.previewSize;
                final aspectRatio =
                    size != null ? size.width / size.height : 3 / 4;

                return Center(
                  child: Stack(
                    children: [
                      AspectRatio(
                        aspectRatio: aspectRatio,
                        child: CameraPreview(controller),
                      ),
                      if (_mainImage != null && isStep1 == false)
                        Positioned(
                          right: 12,
                          top: 12,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              width: 90,
                              height: 120,
                              color: Colors.black,
                              child: Image.memory(
                                _mainImage!,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: FloatingActionButton.extended(
              onPressed: _onCapturePressed,
              icon: const Icon(Icons.camera_alt),
              label: Text(isStep1 ? 'Moment aufnehmen' : 'Selfie aufnehmen'),
            ),
          ),
        ],
      ),
    );
  }
}
