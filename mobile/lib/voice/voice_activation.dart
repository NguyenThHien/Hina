abstract class VoiceActivation {
  /// Phát một sự kiện mỗi lần nghe thấy từ khóa đánh thức.
  Stream<void> get onWake;
  Future<void> start();
  Future<void> stop();
}

// ponytail: chưa có wake-word; người dùng kích hoạt bằng nút. Engine thật (openWakeWord/Porcupine) cắm vào đây.
class NoopVoiceActivation implements VoiceActivation {
  @override
  Stream<void> get onWake => const Stream<void>.empty();

  @override
  Future<void> start() async {}

  @override
  Future<void> stop() async {}
}
