import 'dart:typed_data';

abstract class AudioCapture {
  Future<void> start();

  /// Dừng và trả về PCM16 mono 16 kHz đã thu (rỗng nếu chưa có gì).
  Future<Uint8List> stop();
}
