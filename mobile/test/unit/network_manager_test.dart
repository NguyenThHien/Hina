import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hina_mobile/network/network_manager.dart';
import 'package:hina_mobile/network/server_event.dart';

void main() {
  late HttpServer server;
  late int posts;

  setUp(() async {
    posts = 0;
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((req) async {
      try {
        if (req.method == 'POST' && req.uri.path == '/sessions') {
          posts++;
          req.response
            ..statusCode = 201
            ..headers.contentType = ContentType.json
            ..write(jsonEncode({'session_id': 's$posts', 'token': 't'}));
          await req.response.close();
        } else if (req.uri.path == '/ws' && WebSocketTransformer.isUpgradeRequest(req)) {
          final socket = await WebSocketTransformer.upgrade(req);
          socket.listen((_) {}, onDone: socket.close);
        } else {
          req.response.statusCode = 404;
          await req.response.close();
        }
      } on Exception {
        // kết nối thử nghiệm: lỗi đóng socket không ảnh hưởng assertion
      }
    });
  });

  tearDown(() => server.close(force: true));

  test('endSession đóng kết nối và không tự kết nối lại', () async {
    final network = HttpWsNetworkManager('http://127.0.0.1:${server.port}');
    final events = <ServerEvent>[];
    final sub = network.events.listen(events.add);
    addTearDown(() async {
      await sub.cancel();
      await network.close();
    });

    await network.connect();
    expect(network.isConnected, isTrue);
    expect(posts, 1);

    await network.endSession();
    expect(network.isConnected, isFalse);

    await Future<void>.delayed(const Duration(milliseconds: 1500));
    expect(posts, 1);
    expect(events.whereType<DisconnectedEvent>(), isEmpty);
  });

  test('connect sau endSession mở phiên mới', () async {
    final network = HttpWsNetworkManager('http://127.0.0.1:${server.port}');
    addTearDown(network.close);

    await network.connect();
    await network.endSession();
    await network.connect();

    expect(posts, 2);
    expect(network.isConnected, isTrue);
  });
}
