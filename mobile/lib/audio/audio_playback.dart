import 'package:flutter_tts/flutter_tts.dart';

abstract class AudioPlayback {
  Future<void> speak(String text);
  Future<void> stop();
}

/// Đọc text bằng TTS của điện thoại: độ trễ thấp, chạy được cả khi mất mạng.
class TtsAudioPlayback implements AudioPlayback {
  final _tts = FlutterTts();
  bool _ready = false;

  Future<void> _ensureReady() async {
    if (_ready) return;
    await _tts.setLanguage('vi-VN');
    await _tts.awaitSpeakCompletion(true);
    _ready = true;
  }

  @override
  Future<void> speak(String text) async {
    await _ensureReady();
    await _tts.speak(text);
  }

  @override
  Future<void> stop() => _tts.stop();
}
