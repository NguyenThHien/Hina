import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hina_mobile/audio/audio_capture.dart';
import 'package:hina_mobile/audio/audio_playback.dart';
import 'package:hina_mobile/camera/camera_manager.dart';
import 'package:hina_mobile/network/network_manager.dart';
import 'package:hina_mobile/network/server_event.dart';
import 'package:hina_mobile/permissions/device_permissions.dart';
import 'package:hina_mobile/session/session_controller.dart';

class FakeNetwork implements NetworkManager {
  final _controller = StreamController<ServerEvent>.broadcast();
  final sent = <String>[];
  bool connected = false;

  @override
  Stream<ServerEvent> get events => _controller.stream;
  @override
  bool get isConnected => connected;
  @override
  Future<void> connect() async {}
  @override
  void sendAudio(int requestId, Uint8List pcm) => sent.add('audio:$requestId');
  @override
  void sendImage(int frameId, Uint8List jpeg) => sent.add('image:$frameId');
  @override
  Future<void> close() async {}

  void emit(ServerEvent event) {
    if (event is ConnectedEvent) connected = true;
    if (event is DisconnectedEvent) connected = false;
    _controller.add(event);
  }
}

class FakeCamera implements CameraManager {
  @override
  Future<void> start() async {}
  @override
  Future<Uint8List?> capture() async => Uint8List.fromList([9]);
  @override
  Future<void> stop() async {}
}

class FakeCapture implements AudioCapture {
  @override
  Future<void> start() async {}
  @override
  Future<Uint8List> stop() async => Uint8List.fromList([1, 2, 3]);
}

class FakePlayback implements AudioPlayback {
  final spoken = <String>[];
  @override
  Future<void> speak(String text) async => spoken.add(text);
  @override
  Future<void> stop() async {}
}

class FakePermissions implements Permissions {
  FakePermissions(this.onCheck, this.onRequest);
  PermissionResult onCheck;
  PermissionResult onRequest;
  int settingsOpened = 0;

  @override
  Future<PermissionResult> check() async => onCheck;
  @override
  Future<PermissionResult> request() async => onRequest;
  @override
  Future<void> openSettings() async => settingsOpened++;
}

Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 20));

void main() {
  late FakeNetwork network;
  late FakePlayback playback;
  late FakePermissions perms;

  SessionController build({
    PermissionResult check = PermissionResult.granted,
    PermissionResult request = PermissionResult.granted,
    Duration requestTimeout = const Duration(seconds: 20),
    Duration alertCooldown = const Duration(seconds: 3),
  }) {
    network = FakeNetwork();
    playback = FakePlayback();
    return SessionController(
      network: network,
      camera: FakeCamera(),
      capture: FakeCapture(),
      playback: playback,
      permissions: perms = FakePermissions(check, request),
      requestTimeout: requestTimeout,
      alertCooldown: alertCooldown,
      frameInterval: const Duration(hours: 1), // tắt vòng gửi frame định kỳ trong test
    );
  }

  Future<SessionController> started({
    Duration requestTimeout = const Duration(seconds: 20),
    Duration alertCooldown = const Duration(seconds: 3),
  }) async {
    final c = build(requestTimeout: requestTimeout, alertCooldown: alertCooldown);
    await c.start();
    network.emit(const ConnectedEvent());
    await settle();
    return c;
  }

  Future<void> ask(SessionController c) async {
    await c.toggleListening(); // bắt đầu nghe
    await c.toggleListening(); // gửi
  }

  test('goes ready and announces when connected', () async {
    final c = await started();
    addTearDown(c.dispose);
    expect(c.state, SessionState.ready);
    expect(playback.spoken, ['Sẵn sàng']);
  });

  test('explains and waits for a tap before asking for permissions, then boots', () async {
    final c = build(check: PermissionResult.denied);
    addTearDown(c.dispose);

    await c.start();
    expect(c.state, SessionState.needsPermission);
    expect(playback.spoken.single, contains('camera'));

    await c.toggleListening(); // người dùng bấm -> hiện popup hệ thống -> được cấp
    network.emit(const ConnectedEvent());
    await settle();
    expect(c.state, SessionState.ready);
  });

  test('stays on the permission screen when the user denies the popup', () async {
    final c = build(check: PermissionResult.denied, request: PermissionResult.denied);
    addTearDown(c.dispose);

    await c.start();
    await c.toggleListening();

    expect(c.state, SessionState.needsPermission);
  });

  test('permanently denied sends the user to settings and recovers on return', () async {
    final c = build(
      check: PermissionResult.permanentlyDenied,
      request: PermissionResult.permanentlyDenied,
    );
    addTearDown(c.dispose);

    await c.start();
    expect(c.state, SessionState.permissionBlocked);

    await c.toggleListening();
    expect(perms.settingsOpened, 1);

    perms.onCheck = PermissionResult.granted; // người dùng bật quyền trong Cài đặt
    await c.resume();
    network.emit(const ConnectedEvent());
    await settle();
    expect(c.state, SessionState.ready);
  });

  test('sends image then audio with the same id, speaks matching result, ignores stale ones', () async {
    final c = await started();
    addTearDown(c.dispose);

    await ask(c);
    expect(c.state, SessionState.waiting);
    expect(network.sent, ['image:1', 'audio:1']);

    network.emit(const ResultEvent(requestId: 99, intent: 'READ_TEXT', text: 'cũ'));
    await settle();
    expect(c.state, SessionState.waiting);

    network.emit(const ResultEvent(requestId: 1, intent: 'READ_TEXT', text: 'Nhà thuốc'));
    await settle();
    expect(c.state, SessionState.ready);
    expect(playback.spoken.last, 'Nhà thuốc');
  });

  test('disconnect announces once even if retries keep failing', () async {
    final c = await started();
    addTearDown(c.dispose);

    network.emit(const DisconnectedEvent());
    network.emit(const DisconnectedEvent());
    await settle();

    expect(c.state, SessionState.disconnected);
    expect(playback.spoken.where((s) => s.startsWith('Mất kết nối')), hasLength(1));
  });

  test('repeated identical alerts are spoken once within the cooldown', () async {
    final c = await started();
    addTearDown(c.dispose);
    const alert = AlertEvent(level: 'warning', label: 'person', direction: 'ahead', distanceM: 1.5);

    network.emit(alert);
    network.emit(alert);
    await settle();

    expect(playback.spoken.where((s) => s.contains('người')), hasLength(1));
  });

  test('gives up on a pending request after the timeout', () async {
    final c = await started(requestTimeout: const Duration(milliseconds: 10));
    addTearDown(c.dispose);

    await ask(c);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(c.state, SessionState.ready);
    expect(playback.spoken.last, contains('phản hồi chậm'));
  });
}
