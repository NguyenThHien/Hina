import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:hina_mobile/audio/audio_capture.dart';
import 'package:hina_mobile/voice/voice_activation.dart';
import 'package:record/record.dart';

const _bytesPerSecond = 16000 * 2; // PCM16 mono 16 kHz

/// Một luồng micro dùng chung cho kích hoạt bằng giọng nói (VAD) và thu câu hỏi.
/// Lúc chờ: đo năng lượng, giữ [preRoll] âm thanh gần nhất; nói to liên tục [minSpeech] thì báo [onWake].
/// Lúc thu: đoạn pre-roll được đặt đầu bản ghi để không mất chữ đầu đã kích hoạt VAD.
// ponytail: VAD theo năng lượng (dBFS), dễ kích nhầm ở chỗ ồn; thay bằng Silero VAD nếu thực tế kích nhầm nhiều.
class MicVad implements VoiceActivation {
  MicVad({
    this.thresholdDb = -30,
    this.minSpeech = const Duration(milliseconds: 250),
    this.preRoll = const Duration(milliseconds: 500),
    AudioRecorder? recorder, // test truyền bản giả
  }) : _injected = recorder;

  final AudioRecorder? _injected;

  /// Nút chỉnh độ nhạy: mic mỗi máy một khác, chỉnh theo thử nghiệm thực tế.
  final double thresholdDb;
  final Duration minSpeech;
  final Duration preRoll;

  final _wake = StreamController<void>.broadcast();
  final _buffer = BytesBuilder(copy: false);
  final _ring = <Uint8List>[];
  StreamSubscription<Uint8List>? _sub;
  bool _listening = false; // VAD đang bật
  bool _recording = false;
  Duration _loud = Duration.zero;

  @override
  Stream<void> get onWake => _wake.stream;

  @override
  Future<void> start() async {
    _listening = true;
    await _open();
  }

  @override
  Future<void> stop() async {
    _listening = false;
    if (!_recording) await _close();
  }

  /// Thu câu hỏi trên cùng luồng mic này.
  late final AudioCapture capture = _Capture(this);

  Future<void> _startRecording() async {
    _buffer.clear();
    for (final c in _ring) {
      _buffer.add(c);
    }
    _ring.clear();
    _recording = true;
    await _open();
  }

  Future<Uint8List> _stopRecording() async {
    _recording = false;
    final audio = _buffer.takeBytes();
    if (!_listening) await _close();
    return audio;
  }

  Future<void> _open() async {
    if (_sub != null) return;
    final stream = await _rec.startStream(
      const RecordConfig(encoder: AudioEncoder.pcm16bits, sampleRate: 16000, numChannels: 1),
    );
    _sub = stream.listen(_onChunk);
  }

  Future<void> _close() async {
    await _rec.stop();
    await _sub?.cancel();
    _sub = null;
    _ring.clear();
    _loud = Duration.zero;
  }

  late final AudioRecorder _rec = _injected ?? AudioRecorder();

  void _onChunk(Uint8List chunk) {
    if (_recording) {
      _buffer.add(chunk);
      return;
    }
    _ring.add(chunk);
    var kept = _ring.fold<int>(0, (n, c) => n + c.length);
    final limit = _bytesPerSecond * preRoll.inMilliseconds ~/ 1000;
    while (_ring.length > 1 && kept - _ring.first.length >= limit) {
      kept -= _ring.removeAt(0).length;
    }
    if (!_listening) {
      _loud = Duration.zero;
      return;
    }
    final len = Duration(microseconds: chunk.length * 1000000 ~/ _bytesPerSecond);
    _loud = dbfs(chunk) >= thresholdDb ? _loud + len : Duration.zero;
    if (_loud >= minSpeech) {
      _loud = Duration.zero;
      _wake.add(null);
    }
  }
}

class _Capture implements AudioCapture {
  _Capture(this._mic);

  final MicVad _mic;

  @override
  Future<void> start() => _mic._startRecording();

  @override
  Future<Uint8List> stop() => _mic._stopRecording();
}

/// Mức năng lượng RMS của PCM16 little-endian, tính theo dBFS (0 = to nhất, im lặng ≈ -96).
double dbfs(Uint8List pcm) {
  final samples = pcm.buffer.asByteData(pcm.offsetInBytes, pcm.lengthInBytes);
  final n = pcm.lengthInBytes ~/ 2;
  if (n == 0) return -96;
  var sum = 0.0;
  for (var i = 0; i < n; i++) {
    final s = samples.getInt16(i * 2, Endian.little) / 32768;
    sum += s * s;
  }
  final rms = math.sqrt(sum / n);
  return rms == 0 ? -96 : 20 * math.log(rms) / math.ln10;
}
