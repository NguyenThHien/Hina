import 'dart:async';

import 'package:hina_mobile/audio/audio_playback.dart';

/// Hàng đợi đọc tiếng: cảnh báo nguy hiểm được ưu tiên tuyệt đối và lặp tối đa
/// [dangerRepeats] lần; kết quả và thông báo chờ đọc sau.
class SpeechQueue {
  SpeechQueue(
    this._playback, {
    this.dangerRepeats = 3,
    this.repeatGap = const Duration(milliseconds: 1500),
    this.maxPending = 8,
  });

  final AudioPlayback _playback;
  final int dangerRepeats;
  final Duration repeatGap;
  final int maxPending;

  final _messages = <String>[];
  String? _result;
  String? _danger;
  int _generation = 0;
  bool _speaking = false;
  bool _scheduled = false;

  /// Ngắt lời đang đọc, đọc cảnh báo mới ngay và lặp lại.
  void danger(String text) {
    if (text.isEmpty) return;
    _generation++;
    _danger = text;
    unawaited(_playback.stop());
    _schedule();
  }

  /// Kết quả mới nhất thay thế kết quả đang chờ (chưa đọc).
  void result(String text) {
    if (text.isEmpty) return;
    _result = text;
    _schedule();
  }

  /// Thông báo trạng thái, đọc theo thứ tự; giữ tối đa [maxPending] câu.
  void announce(String text) {
    if (text.isEmpty) return;
    if (_messages.length >= maxPending) _messages.removeAt(0);
    _messages.add(text);
    _schedule();
  }

  /// Bỏ mọi câu chưa đọc và ngắt lời đang đọc.
  Future<void> clear() async {
    _generation++;
    _result = null;
    _danger = null;
    _messages.clear();
    await _playback.stop();
  }

  /// Ngắt lời đang đọc rồi đọc đúng [text] một lần (dùng cho lời kết thúc phiên).
  Future<void> sayNow(String text) async {
    _generation++;
    _result = null;
    _danger = null;
    _messages.clear();
    await _playback.stop();
    if (text.isNotEmpty) await _playback.speak(text);
  }

  void _schedule() {
    if (_speaking || _scheduled) return;
    _scheduled = true;
    Future<void>.microtask(() {
      _scheduled = false;
      unawaited(_pump());
    });
  }

  Future<void> _pump() async {
    if (_speaking) return;
    _speaking = true;
    try {
      while (true) {
        final danger = _danger;
        if (danger != null) {
          _danger = null;
          final generation = _generation;
          for (var i = 0; i < dangerRepeats; i++) {
            if (generation != _generation) break;
            if (i > 0) {
              await Future<void>.delayed(repeatGap);
              if (generation != _generation) break;
            }
            await _playback.speak(danger);
          }
          continue;
        }
        final result = _result;
        if (result != null) {
          _result = null;
          await _playback.speak(result);
          continue;
        }
        if (_messages.isEmpty) break;
        await _playback.speak(_messages.removeAt(0));
      }
    } finally {
      _speaking = false;
    }
  }
}
