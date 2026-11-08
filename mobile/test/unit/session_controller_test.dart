import 'package:flutter_test/flutter_test.dart';
import 'package:hina_mobile/network/server_event.dart';
import 'package:hina_mobile/permissions/device_permissions.dart';
import 'package:hina_mobile/session/session_controller.dart';

import '../support/fakes.dart';

Future<void> settle([int ms = 20]) => Future<void>.delayed(Duration(milliseconds: ms));

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
      dangerRepeatGap: const Duration(milliseconds: 1),
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

  test('leaving the record screen mid-recording discards the audio', () async {
    final c = await started();
    addTearDown(c.dispose);
    await c.toggleListening();
    await c.cancelListening();
    await settle();

    expect(c.state, SessionState.ready);
    expect(network.sent.where((m) => m.startsWith('audio')), isEmpty);
  });

  test('voice guide off silences status but still speaks answers', () async {
    final c = build()..voiceGuide = false;
    addTearDown(c.dispose);
    await c.start();
    network.emit(const ConnectedEvent());
    await settle();
    expect(playback.spoken, isEmpty);

    await ask(c);
    network.emit(const ResultEvent(requestId: 1, intent: 'READ_TEXT', text: 'Nhà thuốc'));
    await settle();
    expect(playback.spoken, ['Nhà thuốc']);
  });

  test('END_SESSION ends the session, speaks goodbye and stops reconnecting', () async {
    final c = await started();
    addTearDown(c.dispose);

    await ask(c);
    network.emit(const ResultEvent(requestId: 1, intent: 'END_SESSION', text: 'Đã kết thúc phiên.'));
    await settle();

    expect(c.state, SessionState.ended);
    expect(network.endSessionCalled, isTrue);
    expect(playback.spoken.last, 'Đã kết thúc phiên.');

    network.emit(const DisconnectedEvent());
    await settle();
    expect(c.state, SessionState.ended);
  });

  test('startNewSession connects again after the session ended', () async {
    final c = await started();
    addTearDown(c.dispose);
    expect(network.connects, 1);

    await ask(c);
    network.emit(const ResultEvent(requestId: 1, intent: 'END_SESSION', text: 'Tạm biệt'));
    await settle();

    await c.startNewSession();
    expect(network.connects, 2);
    expect(c.state, SessionState.init);

    network.emit(const ConnectedEvent());
    await settle();
    expect(c.state, SessionState.ready);
  });

  test('danger alerts repeat three times', () async {
    final c = await started();
    addTearDown(c.dispose);
    const alert = AlertEvent(level: 'danger', label: 'car', direction: 'ahead', distanceM: 0.8);

    network.emit(alert);
    await settle(120);

    expect(playback.spoken.where((s) => s.startsWith('Nguy hiểm')), hasLength(3));
  });
}
