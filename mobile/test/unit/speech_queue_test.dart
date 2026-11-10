import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hina_mobile/audio/audio_playback.dart';
import 'package:hina_mobile/audio/speech_queue.dart';

class _FakePlayback implements AudioPlayback {
  final spoken = <String>[];
  bool holdNext = false;
  Completer<void>? _gate;
  final played = <int>[];
  Object? playError;

  @override
  Future<void> play(Uint8List mp3) async {
    played.add(mp3.length);
    if (playError case final e?) throw e;
  }


  @override
  Future<void> speak(String text) async {
    spoken.add(text);
    if (holdNext) {
      holdNext = false;
      _gate = Completer<void>();
      await _gate!.future;
    }
  }

  @override
  Future<void> stop() async {
    final gate = _gate;
    _gate = null;
    if (gate != null && !gate.isCompleted) gate.complete();
  }
}

Future<void> _settle([int ms = 80]) => Future<void>.delayed(Duration(milliseconds: ms));

void main() {
  test('cảnh báo ngắt lời đang đọc và được đọc ngay', () async {
    final playback = _FakePlayback()..holdNext = true;
    final queue = SpeechQueue(playback, repeatGap: const Duration(milliseconds: 5));

    queue.announce('câu dài');
    await Future<void>.delayed(Duration.zero);
    expect(playback.spoken, ['câu dài']);

    queue.danger('Nguy hiểm');
    await _settle();

    expect(playback.spoken, ['câu dài', 'Nguy hiểm', 'Nguy hiểm', 'Nguy hiểm']);
  });

  test('cảnh báo lặp đúng 3 lần', () async {
    final playback = _FakePlayback();
    final queue = SpeechQueue(playback, repeatGap: const Duration(milliseconds: 1));

    queue.danger('Có xe');
    await _settle();

    expect(playback.spoken, ['Có xe', 'Có xe', 'Có xe']);
  });

  test('cảnh báo mới thay cảnh báo đang lặp', () async {
    final playback = _FakePlayback();
    final queue = SpeechQueue(playback, repeatGap: const Duration(milliseconds: 50));

    queue.danger('Có xe');
    await _settle(10);
    queue.danger('Có hố');
    await _settle(200);

    expect(playback.spoken.first, 'Có xe');
    expect(playback.spoken.where((t) => t == 'Có hố').length, 3);
    expect(playback.spoken.where((t) => t == 'Có xe').length, 1);
  });

  test('kết quả chờ sau khi đọc xong cảnh báo', () async {
    final playback = _FakePlayback();
    final queue = SpeechQueue(playback, repeatGap: const Duration(milliseconds: 1));

    queue.announce('A');
    queue.danger('D');
    await _settle();

    expect(playback.spoken, ['D', 'D', 'D', 'A']);
  });

  test('kết quả mới thay kết quả chưa đọc', () async {
    final playback = _FakePlayback();
    final queue = SpeechQueue(playback);

    queue.result('A');
    queue.result('B');
    await _settle();

    expect(playback.spoken, ['B']);
  });

  test('hàng đợi giới hạn 8 câu, bỏ câu cũ nhất', () async {
    final playback = _FakePlayback();
    final queue = SpeechQueue(playback);
    for (var i = 1; i <= 20; i++) {
      queue.announce('$i');
    }
    await _settle();

    expect(playback.spoken.length, 8);
    expect(playback.spoken.first, '13');
    expect(playback.spoken.last, '20');
  });

  test('clear bỏ câu chờ và không đọc tiếp', () async {
    final playback = _FakePlayback()..holdNext = true;
    final queue = SpeechQueue(playback);

    queue.announce('A');
    await Future<void>.delayed(Duration.zero);
    queue.announce('B');
    await queue.clear();
    await _settle();

    expect(playback.spoken, ['A']);
  });

  test('kết quả có MP3 thì phát MP3, không đọc text', () async {
    final playback = _FakePlayback();
    SpeechQueue(playback).result('xin chào', audio: Uint8List.fromList([1, 2, 3]));
    await _settle();
    expect(playback.played, [3]);
    expect(playback.spoken, isEmpty);
  });

  test('phát MP3 lỗi thì đọc text bằng TTS máy', () async {
    final playback = _FakePlayback()..playError = Exception('codec');
    SpeechQueue(playback).result('xin chào', audio: Uint8List.fromList([1]));
    await _settle();
    expect(playback.spoken, ['xin chào']);
  });
}
