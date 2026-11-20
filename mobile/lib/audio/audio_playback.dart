import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';

abstract class AudioPlayback {
  Future<void> speak(String text);

  /// Phát audio TTS của server (WAV hoặc MP3), chờ tới khi phát xong hoặc bị [stop].
  Future<void> play(Uint8List audio);
  Future<void> stop();
}

/// Câu trả lời: phát audio TTS từ server (WAV của MMS hoặc MP3 của FPT). Trạng thái, cảnh báo và câu trả lời thiếu audio:
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
  Future<void> play(Uint8List audio) async {
    // Đăng ký trước khi play để không lỡ sự kiện kết thúc.
    final done = _player.onPlayerStateChanged
        .firstWhere((s) => s == PlayerState.completed || s == PlayerState.stopped);
    await _player.play(BytesSource(audio, mimeType: _isWav(audio) ? 'audio/wav' : 'audio/mpeg'));
    await done;
  }

  @override
  Future<void> stop() async {
    await _tts.stop();
    await _player.stop();
  }
}

/// Header RIFF....WAVE: WAV (MMS-TTS); còn lại coi là MP3.
bool _isWav(Uint8List b) =>
    b.length >= 12 && b[0] == 0x52 && b[1] == 0x49 && b[2] == 0x46 && b[3] == 0x46 &&
    b[8] == 0x57 && b[9] == 0x41 && b[10] == 0x56 && b[11] == 0x45;
