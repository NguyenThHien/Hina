import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hina_mobile/audio/audio_capture.dart';
import 'package:hina_mobile/audio/audio_playback.dart';
import 'package:hina_mobile/audio/speech_queue.dart';
import 'package:hina_mobile/camera/camera_manager.dart';
import 'package:hina_mobile/network/network_manager.dart';
import 'package:hina_mobile/network/server_event.dart';
import 'package:hina_mobile/permissions/device_permissions.dart';
import 'package:hina_mobile/voice/voice_activation.dart';

enum SessionState {
  init,
  needsPermission,
  permissionBlocked,
  ready,
  listening,
  waiting,
  disconnected,
  error,
  ended,
}

const _askPermissionMessage =
    'Hina cần camera để nhìn đường và micro để nghe bạn. Vào Cài đặt, chọn Quản lý quyền truy cập.';
const _blockedMessage =
    'Quyền camera hoặc micro đang bị chặn. Vào Cài đặt, chọn Quản lý quyền truy cập.';

/// Khối điều phối trung tâm: quyết định khi nào thu âm, chụp ảnh, gửi, đọc kết quả.
class SessionController extends ChangeNotifier {
  SessionController({
    required this.network,
    required this.camera,
    required this.capture,
    required this.playback,
    required this.permissions,
    this.voice,
    this.maxListen = const Duration(seconds: 15),
    this.requestTimeout = const Duration(seconds: 20),
    this.frameInterval = const Duration(milliseconds: 700),
    this.alertCooldown = const Duration(seconds: 3),
    this.dangerRepeatGap = const Duration(milliseconds: 1500),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final NetworkManager network;
  final CameraManager camera;
  final AudioCapture capture;
  final AudioPlayback playback;
  final Permissions permissions;
  final VoiceActivation? voice;
  final Duration maxListen;
  final Duration requestTimeout;
  final Duration frameInterval;
  final Duration alertCooldown;
  final Duration dangerRepeatGap;
  final DateTime Function() _now;

  late final SpeechQueue _speech = SpeechQueue(playback, repeatGap: dangerRepeatGap);

  SessionState _state = SessionState.init;
  String _message = 'Đang khởi động';
  int _nextRequestId = 1;
  int? _pendingId;
  bool _paused = false;
  bool _booted = false;
  bool _capturingFrame = false;
  String? _lastAlertKey;
  DateTime? _lastAlertAt;

  Timer? _frameTimer;
  Timer? _listenCap;
  Timer? _timeout;
  StreamSubscription<ServerEvent>? _eventSub;
  StreamSubscription<void>? _wakeSub;

  SessionState get state => _state;
  String get message => _message;

  /// Tắt thì không đọc trạng thái ("Sẵn sàng", mất kết nối, xin quyền).
  /// Câu trả lời, lỗi của yêu cầu và cảnh báo an toàn luôn được đọc.
  bool voiceGuide = true;

  Future<void> start() async {
    try {
      await _handlePermission(await permissions.check());
    } on Exception {
      _fail('Không khởi động được ứng dụng.');
    }
  }

  /// Bắt đầu phiên mới sau khi phiên trước đã kết thúc.
  Future<void> startNewSession() async {
    if (_state != SessionState.ended) return;
    _stopFrames();
    _clearPending();
    _listenCap?.cancel();
    _lastAlertKey = null;
    _lastAlertAt = null;
    _set(SessionState.init, 'Đang khởi động');
    await _speech.clear();
    try {
      await _handlePermission(await permissions.check());
    } on Exception {
      _fail('Không khởi động được ứng dụng.');
    }
  }

  /// Nút chính màn Ghi âm: bắt đầu nói hoặc gửi. Nhánh quyền là dự phòng
  /// (UI đưa người dùng tới màn Cấp quyền).
  Future<void> toggleListening() async {
    switch (_state) {
      case SessionState.needsPermission:
        await _requestPermissions();
      case SessionState.permissionBlocked:
        await permissions.openSettings();
      case SessionState.ready:
        await _startListening();
      case SessionState.listening:
        await _finishListening();
      default:
        break;
    }
  }

  Future<void> _requestPermissions() async {
    try {
      await _handlePermission(await permissions.request());
    } on Exception {
      _fail('Không khởi động được ứng dụng.');
    }
  }

  Future<void> _handlePermission(PermissionResult result) async {
    switch (result) {
      case PermissionResult.granted:
        _set(SessionState.init, 'Đang khởi động');
        await _boot();
      case PermissionResult.denied:
        _set(SessionState.needsPermission, _askPermissionMessage);
        _announce(_askPermissionMessage);
      case PermissionResult.permanentlyDenied:
        _set(SessionState.permissionBlocked, _blockedMessage);
        _announce(_blockedMessage);
    }
  }

  Future<void> _boot() async {
    if (!_booted) {
      _booted = true;
      _eventSub = network.events.listen(_onEvent);
      _wakeSub = voice?.onWake.listen((_) {
        if (_state == SessionState.ready) unawaited(toggleListening());
      });
      await voice?.start();
    }
    await camera.start();
    if (!network.isConnected) await network.connect();
  }

  Future<void> pause() async {
    if (_paused) return;
    _paused = true;
    _stopFrames();
    await camera.stop();
  }

  Future<void> resume() async {
    if (_state == SessionState.ended) return;
    if (_state == SessionState.permissionBlocked) {
      // Người dùng có thể vừa bật quyền trong Cài đặt; chỉ hành động nếu đã được cấp.
      if (await permissions.check() == PermissionResult.granted) {
        await _handlePermission(PermissionResult.granted);
      }
      return;
    }
    if (!_paused) return;
    _paused = false;
    await camera.start();
    if (network.isConnected) _startFrames();
  }

  Future<void> _startListening() async {
    await _speech.clear();
    try {
      await capture.start();
    } on Exception {
      _fail('Không thu được âm thanh.');
      return;
    }
    _set(SessionState.listening, 'Đang ghi âm, bấm Dừng ghi âm để gửi');
    _listenCap = Timer(maxListen, () => unawaited(_finishListening()));
  }

  Future<void> _finishListening() async {
    if (_state != SessionState.listening) return;
    _listenCap?.cancel();
    _set(SessionState.waiting, 'Đang xử lý'); // chặn gọi lặp trong lúc await
    final audio = await capture.stop();
    final image = await _captureOrNull();
    if (_state != SessionState.waiting) return; // rớt mạng trong lúc chờ
    if (audio.isEmpty) {
      _set(SessionState.ready, 'Sẵn sàng');
      return;
    }
    if (!network.isConnected) {
      _onDisconnected();
      return;
    }
    final id = _nextRequestId++;
    _pendingId = id;
    if (image != null) network.sendImage(id, image); // ảnh mới nhất cho request này
    network.sendAudio(id, audio);
    _timeout = Timer(requestTimeout, _onTimeout);
  }

  /// Rời màn ghi âm giữa chừng: bỏ đoạn đang thu, không gửi.
  Future<void> cancelListening() async {
    if (_state != SessionState.listening) return;
    _listenCap?.cancel();
    _set(SessionState.ready, 'Sẵn sàng');
    await capture.stop();
  }

  void _onEvent(ServerEvent event) {
    switch (event) {
      case ConnectedEvent():
        _onConnected();
      case DisconnectedEvent():
        _onDisconnected();
      case ResultEvent r:
        _onResult(r);
      case AlertEvent a:
        _onAlert(a);
      case ErrorEvent e:
        _onError(e);
      case PongEvent():
        break;
    }
  }

  void _onConnected() {
    if (_state == SessionState.ended) return;
    if (_state == SessionState.init || _state == SessionState.disconnected) {
      _set(SessionState.ready, 'Sẵn sàng');
      _announce('Sẵn sàng');
    }
    if (!_paused) _startFrames();
  }

  void _onDisconnected() {
    if (_state == SessionState.ended) return;
    if (_state == SessionState.disconnected) return; // mỗi lần retry hỏng lại phát sự kiện
    _stopFrames();
    _clearPending();
    _listenCap?.cancel();
    if (_state == SessionState.listening) unawaited(capture.stop());
    _set(SessionState.disconnected, 'Mất kết nối, đang thử lại');
    _announce('Mất kết nối, đang thử lại');
  }

  void _onResult(ResultEvent r) {
    if (r.requestId != _pendingId) return; // phản hồi cũ/không còn hợp lệ
    _clearPending();
    if (r.intent == 'END_SESSION') {
      _onEnded(r.text);
      return;
    }
    _set(SessionState.ready, r.text);
    _speech.result(r.text);
  }

  /// Server đã kết thúc phiên: dừng mọi hoạt động, đọc lời tạm biệt, không tự kết nối lại.
  void _onEnded(String text) {
    _stopFrames();
    _listenCap?.cancel();
    if (_state == SessionState.listening) unawaited(capture.stop());
    _set(SessionState.ended, text);
    unawaited(_speech.sayNow(text));
    unawaited(network.endSession());
    unawaited(camera.stop());
  }

  void _onError(ErrorEvent e) {
    if (e.requestId == null || e.requestId != _pendingId) return;
    _clearPending();
    _set(SessionState.ready, 'Có lỗi, bạn thử lại nhé');
    _speech.announce('Có lỗi, bạn thử lại nhé');
  }

  void _onAlert(AlertEvent a) {
    if (_state == SessionState.ended) return;
    final key = '${a.level}/${a.label}/${a.direction}';
    final now = _now();
    final last = _lastAlertAt;
    if (key == _lastAlertKey && last != null && now.difference(last) < alertCooldown) return;
    _lastAlertKey = key;
    _lastAlertAt = now;
    if (a.level == 'danger') {
      _speech.danger(a.speech);
    } else {
      _speech.announce(a.speech);
    }
  }

  void _onTimeout() {
    if (_pendingId == null) return;
    _clearPending();
    _set(SessionState.ready, 'Máy chủ phản hồi chậm, bạn thử lại nhé');
    _speech.announce('Máy chủ phản hồi chậm, bạn thử lại nhé');
  }

  void _clearPending() {
    _pendingId = null;
    _timeout?.cancel();
  }

  void _startFrames() {
    _frameTimer?.cancel();
    _frameTimer = Timer.periodic(frameInterval, (_) => unawaited(_sendFrame()));
  }

  void _stopFrames() {
    _frameTimer?.cancel();
    _frameTimer = null;
  }

  Future<void> _sendFrame() async {
    if (_capturingFrame || !network.isConnected) return;
    _capturingFrame = true;
    try {
      final image = await _captureOrNull();
      if (image != null) network.sendImage(0, image);
    } finally {
      _capturingFrame = false;
    }
  }

  Future<Uint8List?> _captureOrNull() async {
    try {
      return await camera.capture();
    } on Exception {
      return null;
    }
  }

  void _announce(String text) {
    if (voiceGuide) _speech.announce(text);
  }

  void _fail(String message) {
    _set(SessionState.error, message);
    _speech.announce(message);
  }

  void _set(SessionState state, String message) {
    _state = state;
    _message = message;
    notifyListeners();
  }

  @override
  void dispose() {
    _stopFrames();
    _listenCap?.cancel();
    _timeout?.cancel();
    unawaited(_eventSub?.cancel());
    unawaited(_wakeSub?.cancel());
    unawaited(voice?.stop());
    unawaited(_speech.clear());
    unawaited(network.close());
    unawaited(camera.stop());
    super.dispose();
  }
}
