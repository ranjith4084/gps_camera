import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gallery_saver_plus/gallery_saver.dart';
import 'package:geolocator/geolocator.dart';
import 'package:gps_camera/src/preview_page.dart';
import 'package:permission_handler/permission_handler.dart';

import 'geo_image_watermark.dart';
import 'grid_overlay.dart';
import 'sensor_overlay.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;

  int _cameraIndex = 0;
  FlashMode _flashMode = FlashMode.off;
  bool _loading = true;

  @override
  void initState() {
    super.initState();

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);

    _init();
  }

  Future<void> _init() async {
    final cam = await Permission.camera.request();
    final loc = await Geolocator.requestPermission();

    if (!cam.isGranted ||
        (loc != LocationPermission.whileInUse &&
            loc != LocationPermission.always)) {
      await openAppSettings();
      return;
    }

    _cameras = await availableCameras();
    await _startCamera();
  }

  Future<void> _startCamera() async {
    final controller = CameraController(
      _cameras![_cameraIndex],
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    await controller.initialize();
    await controller.lockCaptureOrientation(DeviceOrientation.portraitUp);

    _controller = controller;
    setState(() => _loading = false);
  }

  Future<void> _switchCamera() async {
    _cameraIndex = (_cameraIndex + 1) % _cameras!.length;
    await _controller?.dispose();
    await _startCamera();
  }

  Future<void> _toggleFlash() async {
    _flashMode =
    _flashMode == FlashMode.off ? FlashMode.torch : FlashMode.off;
    await _controller!.setFlashMode(_flashMode);
    setState(() {});
  }

  Future<void> _capture() async {
    if (!_controller!.value.isInitialized ||
        _controller!.value.isTakingPicture) return;

    final XFile file = await _controller!.takePicture();

    final stamped = await GeoImageWatermark.stamp(
      imageFile: File(file.path),
    );

    if (!mounted) return;

    // Navigate to preview screen
    final File? result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PreviewPage(imageFile: stamped),
      ),
    );

    // If user pressed SAVE → return to HomePage
    if (result != null && mounted) {
      Navigator.pop(context, result);
    }
  }
  @override
  void dispose() {
    _controller?.dispose();
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  Widget _buildCameraPreview() {
    return Center(
      child: AspectRatio(
        aspectRatio: 1 / _controller!.value.aspectRatio,
        child: CameraPreview(_controller!),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _controller == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          _buildCameraPreview(),
          const GridOverlay(),
          const SensorOverlay(),

          Positioned(
            top: 40,
            left: 20,
            child: IconButton(
              icon: const Icon(Icons.cameraswitch,
                  color: Colors.white, size: 30),
              onPressed: _switchCamera,
            ),
          ),

          Positioned(
            top: 40,
            right: 20,
            child: IconButton(
              icon: Icon(
                _flashMode == FlashMode.off
                    ? Icons.flash_off
                    : Icons.flash_on,
                color: Colors.white,
                size: 30,
              ),
              onPressed: _toggleFlash,
            ),
          ),

          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: FloatingActionButton(
                onPressed: _capture,
                child: const Icon(Icons.camera_alt),
              ),
            ),
          ),
        ],
      ),
    );
  }
}