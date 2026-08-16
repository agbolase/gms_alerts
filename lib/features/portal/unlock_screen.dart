import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../config/app_config.dart';
import '../../services/alert_api.dart';
import '../../services/biometric_gate.dart';
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
  var _scanning = false;

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
      await cam.dispose();
    } catch (_) {}
  }

  Future<void> _startFaceCamera() async {
    setState(() {
      _error = null;
      _starting = true;
    });
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      if (!mounted) return;
      setState(() {
        _starting = false;
        _error = 'Camera permission is needed for face unlock.';
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
      );
      await controller.initialize();
      _detector ??= FaceDetector(
        options: FaceDetectorOptions(
          performanceMode: FaceDetectorMode.accurate,
          minFaceSize: 0.15,
        ),
      );
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _camera = controller;
        _starting = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _starting = false;
        _error = 'Could not open the camera. Try password.';
      });
    }
  }

  Future<void> _scanFace() async {
    final cam = _camera;
    if (_scanning || cam == null || !cam.value.isInitialized) {
      await _startFaceCamera();
      return;
    }
    setState(() {
      _scanning = true;
      _error = null;
    });
    try {
      if (cam.value.isStreamingImages) {
        await cam.stopImageStream();
      }
      await cam.pausePreview();
      final shot = await cam.takePicture();
      try {
        await cam.resumePreview();
      } catch (_) {}
      try {
        final detector = _detector ??
            FaceDetector(
              options: FaceDetectorOptions(
                performanceMode: FaceDetectorMode.accurate,
                minFaceSize: 0.15,
              ),
            );
        _detector = detector;
        final faces = await detector.processImage(InputImage.fromFilePath(shot.path));
        if (faces.isEmpty) {
          if (!mounted) return;
          setState(() => _error = 'No face found. Hold the phone in front of your face and scan again.');
          return;
        }
      } catch (_) {
        // Still send the photo if on-device detection is unavailable.
      }
      final bytes = await File(shot.path).readAsBytes();
      if (bytes.length < 200) {
        if (!mounted) return;
        setState(() => _error = 'Camera did not capture a photo. Tap Scan face again.');
        return;
      }
      final hint = await AlertApi.lastUserId();
      final data = await AlertApi.faceLogin(bytes, userId: hint);
      if (!mounted) return;
      if (data['success'] == true && '${data['login_url'] ?? ''}'.isNotEmpty) {
        final user = data['user'];
        if (user is Map && user['id'] != null) {
          await AlertApi.saveLastUserId(int.tryParse('${user['id']}') ?? 0);
        }
        await _stopCamera();
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => PortalScreen(initialUrl: '${data['login_url']}'),
          ),
        );
        return;
      }
      setState(() {
        _error = '${data['message'] ?? 'Face not recognised. Enrol a face photo at school, or use password.'}';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Could not scan face. ${e.toString().replaceFirst('Exception: ', '')}');
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  Future<void> _tryFingerprint() async {
    setState(() => _error = null);
    final result = await BiometricGate.unlock();
    if (!mounted) return;
    if (result.ok) {
      await _stopCamera();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const PortalScreen()),
      );
      return;
    }
    if (result.error != null) {
      setState(() => _error = result.error);
    }
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
                  'Look at the camera, then tap Scan face',
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
                  onPressed: (_starting || _scanning) ? null : _scanFace,
                  child: Text(_scanning ? 'Matching…' : 'Scan face'),
                ),
                TextButton(
                  onPressed: _scanning ? null : _tryFingerprint,
                  child: const Text('Use fingerprint'),
                ),
                TextButton(
                  onPressed: _scanning
                      ? null
                      : () async {
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
