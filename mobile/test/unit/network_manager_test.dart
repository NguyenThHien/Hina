import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hina_mobile/core/protocol.dart';
import 'package:hina_mobile/network/network_manager.dart';
import 'package:hina_mobile/network/server_event.dart';

void main() {
  late HttpServer server;
  late int posts;
  var toSend = <Object>[];

  setUp(() async {
    posts = 0;
    toSend = [];
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
          toSend.forEach(socket.add);
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

  test('khung TTS trước result được gắn vào result cùng request_id', () async {
    toSend = [
      encodeFrame(Kind.tts, 4, Uint8List.fromList([7, 7])),
      jsonEncode({'type': 'result', 'request_id': 4, 'intent': 'READ_TEXT', 'text': 'a'}),
      jsonEncode({'type': 'result', 'request_id': 5, 'intent': 'READ_TEXT', 'text': 'b'}),
    ];
    final network = HttpWsNetworkManager('http://127.0.0.1:${server.port}');
    addTearDown(network.close);
    final results = <ResultEvent>[];
    final got = Completer<void>();
    network.events.listen((e) {
      if (e is ResultEvent) results.add(e);
      if (results.length == 2 && !got.isCompleted) got.complete();
    });

    await network.connect();
    await got.future.timeout(const Duration(seconds: 5));

    expect(results[0].audio, [7, 7]);
    expect(results[1].audio, isNull);
  });
}
