abstract class VoiceActivation {
  /// Phát một sự kiện mỗi lần nghe thấy từ khóa đánh thức.
  Stream<void> get onWake;
  Future<void> start();
  Future<void> stop();
}
