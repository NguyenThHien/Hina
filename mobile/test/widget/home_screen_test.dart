import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hina_mobile/network/server_event.dart';
import 'package:hina_mobile/permissions/device_permissions.dart';
import 'package:hina_mobile/session/session_controller.dart';
import 'package:hina_mobile/ui/home_screen.dart';
import 'package:hina_mobile/ui/widgets.dart';

import '../support/fakes.dart';

void main() {
  testWidgets('Bắt đầu trò chuyện mở phiên mới sau khi phiên cũ kết thúc', (tester) async {
    final network = FakeNetwork();
    final controller = SessionController(
      network: network,
      camera: FakeCamera(),
      capture: FakeCapture(),
      playback: FakePlayback(),
      permissions: FakePermissions(PermissionResult.granted, PermissionResult.granted),
      frameInterval: const Duration(hours: 1),
      dangerRepeatGap: const Duration(milliseconds: 1),
    );
    addTearDown(controller.dispose);

    await controller.start();
    network.emit(const ConnectedEvent());
    await tester.pump(const Duration(milliseconds: 20));

    await controller.toggleListening();
    await controller.toggleListening();
    network.emit(const ResultEvent(requestId: 1, intent: 'END_SESSION', text: 'Tạm biệt'));
    await tester.pump(const Duration(milliseconds: 20));
    expect(controller.state, SessionState.ended);

    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(useMaterial3: true),
      home: HomeScreen(controller: controller),
      routes: {Routes.record: (_) => const Scaffold(body: Text('record'))},
    ));

    await tester.tap(find.byType(HinaButton));
    await tester.pumpAndSettle();

    expect(network.connects, 2);
    expect(find.text('record'), findsOneWidget);
  });
}
