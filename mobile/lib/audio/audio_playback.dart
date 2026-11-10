import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';

abstract class AudioPlayback {
  Future<void> speak(String text);

  /// Phát MP3 (TTS của server), chờ tới khi phát xong hoặc bị [stop].
  Future<void> play(Uint8List mp3);
  Future<void> stop();
}

/// Câu trả lời: phát MP3 FPT từ server. Trạng thái, cảnh báo và câu trả lời thiếu audio:
/// đọc bằng TTS của điện thoại (độ trễ thấp, chạy được cả khi mất mạng).
class TtsAudioPlayback implements AudioPlayback {
  final _tts = FlutterTts();
  final _player = AudioPlayer();
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
  Future<void> play(Uint8List mp3) async {
    // Đăng ký trước khi play để không lỡ sự kiện kết thúc.
    final done = _player.onPlayerStateChanged
        .firstWhere((s) => s == PlayerState.completed || s == PlayerState.stopped);
    await _player.play(BytesSource(mp3, mimeType: 'audio/mpeg'));
    await done;
  }

  @override
  Future<void> stop() async {
    await _tts.stop();
    await _player.stop();
  }
}
