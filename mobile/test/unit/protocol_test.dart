import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hina_mobile/core/protocol.dart';
import 'package:hina_mobile/network/server_event.dart';

void main() {
  group('frame', () {
    test('encodes header as kind + uint32 big-endian request id (matches server)', () {
      final bytes = encodeFrame(Kind.image, 5, Uint8List.fromList([97, 98]));
      expect(bytes, [2, 0, 0, 0, 5, 97, 98]);
    });

    test('decode is the inverse of encode', () {
      final frame = decodeFrame(encodeFrame(Kind.audio, 70000, Uint8List.fromList([1, 2, 3])));
      expect(frame.kind, Kind.audio);
      expect(frame.requestId, 70000);
      expect(frame.payload, [1, 2, 3]);
    });

    test('rejects short frames and unknown kinds', () {
      expect(() => decodeFrame(Uint8List(0)), throwsA(isA<ProtocolException>()));
      expect(() => decodeFrame(Uint8List.fromList([2, 0])), throwsA(isA<ProtocolException>()));
      expect(
        () => decodeFrame(Uint8List.fromList([99, 0, 0, 0, 1])),
        throwsA(isA<ProtocolException>()),
      );
    });
  });

  group('ServerEvent.fromJson', () {
    test('parses result, alert (with and without distance), error, pong', () {
      final result = ServerEvent.fromJson({
        'type': 'result',
        'request_id': 7,
        'intent': 'READ_TEXT',
        'text': 'Nhà thuốc',
      });
      expect(result, isA<ResultEvent>());

      final alert = ServerEvent.fromJson({
        'type': 'alert',
        'level': 'danger',
        'label': 'person',
        'direction': 'ahead',
        'distance_m': 1.5,
      });
      expect((alert as AlertEvent).speech, 'Nguy hiểm! người phía trước, cách khoảng 1.5 mét');

      final noDistance = ServerEvent.fromJson({
        'type': 'alert',
        'level': 'warning',
        'label': 'car',
        'direction': 'left',
      });
      expect((noDistance as AlertEvent).speech, 'Cẩn thận, ô tô bên trái');

      expect(ServerEvent.fromJson({'type': 'error', 'message': 'x'}), isA<ErrorEvent>());
      expect(ServerEvent.fromJson({'type': 'pong'}), isA<PongEvent>());
    });

    test('returns null for unknown type or wrong field types instead of throwing', () {
      expect(ServerEvent.fromJson({'type': 'nope'}), isNull);
      expect(
        ServerEvent.fromJson({'type': 'result', 'request_id': 'x', 'intent': 1, 'text': null}),
        isNull,
      );
    });
  });
}
