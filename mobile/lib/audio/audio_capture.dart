import 'dart:async';
import 'dart:typed_data';

import 'package:record/record.dart';

abstract class AudioCapture {
  Future<void> start();

  /// Dừng và trả về PCM16 mono 16 kHz đã thu (rỗng nếu chưa có gì).
  Future<Uint8List> stop();
}

// ponytail: chưa có VAD, người dùng bấm để bắt đầu/kết thúc; thêm VAD cắt khoảng lặng sau.
class RecordAudioCapture implements AudioCapture {
  final _recorder = AudioRecorder();
  final _buffer = BytesBuilder();
  StreamSubscription<Uint8List>? _sub;

  @override
  Future<void> start() async {
    _buffer.clear();
    final stream = await _recorder.startStream(
      const RecordConfig(encoder: AudioEncoder.pcm16bits, sampleRate: 16000, numChannels: 1),
    );
    _sub = stream.listen(_buffer.add);
  }

  @override
  Future<Uint8List> stop() async {
    await _recorder.stop();
    await _sub?.cancel();
    _sub = null;
    return _buffer.takeBytes();
  }
}
