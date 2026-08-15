import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../config/app_config.dart';
import '../../services/biometric_gate.dart';
import '../../services/camera_input_image.dart';
import 'portal_screen.dart';

class UnlockScreen extends StatefulWidget {
  const UnlockScreen({super.key});

  @override
  State<UnlockScreen> createState() => _UnlockScreenState();
}

class _UnlockScreenState extends State<UnlockScreen> {
  CameraController? _camera;
  FaceDetector? _detector;
  String? _error;
  var _starting = true;
  var _busy = false;
  var _hits = 0;
  var _unlocked = false;

  @override
  void initState() {
    super.initState();
    _startFaceCamera();
  }

  @override
  void dispose() {
    _stopCamera();
    _detector?.close();
    super.dispose();
  }

  Future<void> _stopCamera() async {
    final cam = _camera;
    _camera = null;
    if (cam == null) return;
    try {
      if (cam.value.isStreamingImages) {
        await cam.stopImageStream();
      }
    } catch (_) {}
    try {
      await cam.dispose();
    } catch (_) {}
  }

  Future<void> _startFaceCamera() async {
    setState(() {
      _error = null;
      _starting = true;
      _hits = 0;
    });
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      if (!mounted) return;
      setState(() {
        _starting = false;
        _error = 'Camera permission is needed for face unlock. Enable it in settings, or use fingerprint / password.';
      });
      return;
    }
    try {
      final cameras = await availableCameras();
      CameraDescription? front;
      for (final c in cameras) {
        if (c.lensDirection == CameraLensDirection.front) {
          front = c;
          break;
        }
      }
      front ??= cameras.isEmpty ? null : cameras.first;
      if (front == null) {
        if (!mounted) return;
        setState(() {
          _starting = false;
          _error = 'No camera found. Use fingerprint or password.';
        });
        return;
      }
      await _stopCamera();
      final controller = CameraController(
        front,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: Platform.isIOS
            ? ImageFormatGroup.bgra8888
            : ImageFormatGroup.nv21,
      );
      await controller.initialize();
      _detector ??= FaceDetector(
        options: FaceDetectorOptions(
          performanceMode: FaceDetectorMode.fast,
          minFaceSize: 0.2,
        ),
      );
      await controller.startImageStream(_onFrame);
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _camera = controller;
        _starting = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _starting = false;
        _error = 'Could not open the camera for face unlock. Try fingerprint or password.';
      });
    }
  }

  Future<void> _onFrame(CameraImage image) async {
    if (_busy || _unlocked) return;
    final cam = _camera;
    final detector = _detector;
    if (cam == null || detector == null || !cam.value.isInitialized) return;
    _busy = true;
    try {
      final input = inputImageFromCamera(
        image: image,
        camera: cam.description,
        controller: cam,
      );
      if (input == null) return;
      final faces = await detector.processImage(input);
      final looking = faces.any((f) {
        final y = f.headEulerAngleY;
        final z = f.headEulerAngleZ;
        if (y != null && y.abs() > 25) return false;
        if (z != null && z.abs() > 25) return false;
        return f.boundingBox.width > 40;
      });
      if (!looking) {
        _hits = 0;
        return;
      }
      _hits++;
      if (_hits >= 8) {
        await _unlockPortal();
      }
    } catch (_) {
      _hits = 0;
    } finally {
      _busy = false;
    }
  }

  Future<void> _unlockPortal() async {
    if (_unlocked) return;
    _unlocked = true;
    await _stopCamera();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const PortalScreen()),
    );
  }

  Future<void> _tryFingerprint() async {
    await _stopCamera();
    if (!mounted) return;
    setState(() => _error = null);
    final result = await BiometricGate.unlock();
    if (!mounted) return;
    if (result.ok) {
      await _unlockPortal();
      return;
    }
    if (result.error != null) {
      setState(() => _error = result.error);
    }
    _unlocked = false;
    await _startFaceCamera();
  }

  @override
  Widget build(BuildContext context) {
    final cam = _camera;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/app_icon.png', width: 72, height: 72),
                const SizedBox(height: 12),
                Text(AppConfig.appName, style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 8),
                const Text(
                  'Look at the camera to unlock with your face',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: 240,
                  height: 240,
                  child: ClipOval(
                    child: ColoredBox(
                      color: const Color(0xFF1A335E),
                      child: cam != null && cam.value.isInitialized
                          ? FittedBox(
                              fit: BoxFit.cover,
                              child: SizedBox(
                                width: cam.value.previewSize?.height ?? 240,
                                height: cam.value.previewSize?.width ?? 240,
                                child: CameraPreview(cam),
                              ),
                            )
                          : Center(
                              child: _starting
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : const Icon(Icons.face, color: Colors.white, size: 64),
                            ),
                    ),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ],
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _starting ? null : _startFaceCamera,
                  child: const Text('Scan face'),
                ),
                TextButton(
                  onPressed: _tryFingerprint,
                  child: const Text('Use fingerprint'),
                ),
                TextButton(
                  onPressed: () async {
                    await _stopCamera();
                    if (!context.mounted) return;
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const PortalScreen()),
                    );
                  },
                  child: const Text('Use password'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
