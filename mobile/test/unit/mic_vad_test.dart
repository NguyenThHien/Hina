import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hina_mobile/voice/mic_vad.dart';
import 'package:record/record.dart';

class _FakeRecorder implements AudioRecorder {
  final chunks = StreamController<Uint8List>();

  @override
  Future<Stream<Uint8List>> startStream(RecordConfig config) async => chunks.stream;

  @override
  Future<String?> stop() async => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// 100 ms PCM16 16 kHz, mọi mẫu = [value].
Uint8List chunk(int value) {
  final d = ByteData(3200);
  for (var i = 0; i < 1600; i++) {
    d.setInt16(i * 2, value, Endian.little);
  }
  return d.buffer.asUint8List();
}

Future<void> flush() => Future<void>.delayed(Duration.zero);

void main() {
  test('dbfs: im lặng rất thấp, toàn thang ≈ 0', () {
    expect(dbfs(chunk(0)), -96);
    expect(dbfs(chunk(32767)), closeTo(0, 0.01));
    expect(dbfs(chunk(1000)), lessThan(-30)); // ồn nền nhỏ không kích hoạt
  });

  test('nói to liên tục đủ lâu thì kích hoạt; tiếng ngắn hoặc nhỏ thì không', () async {
    final rec = _FakeRecorder();
    final vad = MicVad(recorder: rec);
    var wakes = 0;
    vad.onWake.listen((_) => wakes++);
    await vad.start();

    rec.chunks
      ..add(chunk(10000)) // 100 ms to rồi im: tiếng động ngắn
      ..add(chunk(0))
      ..add(chunk(1000))
      ..add(chunk(1000))
      ..add(chunk(1000));
    await flush();
    expect(wakes, 0);

    rec.chunks
      ..add(chunk(10000))
      ..add(chunk(10000))
      ..add(chunk(10000)); // 300 ms ≥ 250 ms
    await flush();
    expect(wakes, 1);
  });

  test('bản thu bắt đầu bằng pre-roll để không mất chữ đầu', () async {
    final rec = _FakeRecorder();
    final vad = MicVad(recorder: rec, preRoll: const Duration(milliseconds: 200));
    await vad.start();
    for (var i = 0; i < 5; i++) {
      rec.chunks.add(chunk(i + 1));
    }
    await flush();

    await vad.capture.start();
    rec.chunks.add(chunk(99));
    await flush();
    final audio = await vad.capture.stop();

    final samples = audio.buffer.asByteData(audio.offsetInBytes);
    expect(audio.length, 3 * 3200); // 200 ms pre-roll + 100 ms thu
    expect(samples.getInt16(0, Endian.little), 4); // giữ 2 khung gần nhất (4, 5)
    expect(samples.getInt16(2 * 3200, Endian.little), 99);
  });
}
