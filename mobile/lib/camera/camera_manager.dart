import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/widgets.dart';

abstract class CameraManager {
  Future<void> start();

  /// Hình camera trực tiếp; dùng chung camera với vòng gửi frame cho Safety.
  Widget preview();

  /// JPEG của khung hình hiện tại, null nếu camera chưa sẵn sàng/đang bận.
  Future<Uint8List?> capture();
  Future<void> stop();
}

// ponytail: takePicture đủ cho ~1-2 fps; cần fps cao thì chuyển sang startImageStream + nén JPEG.
class DeviceCameraManager implements CameraManager {
  final _live = ValueNotifier<CameraController?>(null);
  CameraController? get _controller => _live.value;

  @override
  Future<void> start() async {
    if (_controller != null) return;
    final cameras = await availableCameras();
    final back = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );
    final controller = CameraController(
      back,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );
    await controller.initialize();
    _live.value = controller;
  }

  @override
  Widget preview() => ValueListenableBuilder(
        valueListenable: _live,
        builder: (context, c, _) => c == null ? const SizedBox.expand() : CameraPreview(c),
      );

  @override
  Future<Uint8List?> capture() async {
    final c = _controller;
    if (c == null || !c.value.isInitialized || c.value.isTakingPicture) return null;
    final file = await c.takePicture();
    return file.readAsBytes();
  }

  @override
  Future<void> stop() async {
    final c = _controller;
    _live.value = null;
    await c?.dispose();
  }
}
