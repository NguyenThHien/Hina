// Khung binary WSS, khớp server/src/hina/gateway/protocol.py:
// [1 byte kind][4 byte request_id big-endian][payload]
import 'dart:typed_data';

const headerSize = 5;
const maxFrameBytes = 5 * 1024 * 1024;

enum Kind {
  audio(1), // mobile -> server: 1 lượt nói hoàn chỉnh
  image(2), // mobile -> server: 1 frame JPEG
  tts(3); // server -> mobile

  const Kind(this.code);
  final int code;

  static Kind? fromCode(int code) {
    for (final k in Kind.values) {
      if (k.code == code) return k;
    }
    return null;
  }
}

class Frame {
  const Frame(this.kind, this.requestId, this.payload);
  final Kind kind;
  final int requestId;
  final Uint8List payload;
}

class ProtocolException implements Exception {
  const ProtocolException(this.message);
  final String message;
  @override
  String toString() => 'ProtocolException: $message';
}

Uint8List encodeFrame(Kind kind, int requestId, Uint8List payload) {
  final out = Uint8List(headerSize + payload.length);
  final view = ByteData.sublistView(out);
  view.setUint8(0, kind.code);
  view.setUint32(1, requestId, Endian.big);
  out.setRange(headerSize, out.length, payload);
  return out;
}

Frame decodeFrame(Uint8List data) {
  if (data.length < headerSize || data.length > maxFrameBytes) {
    throw const ProtocolException('bad frame size');
  }
  final view = ByteData.sublistView(data);
  final kind = Kind.fromCode(view.getUint8(0));
  if (kind == null) {
    throw ProtocolException('unknown kind ${view.getUint8(0)}');
  }
  return Frame(kind, view.getUint32(1, Endian.big), Uint8List.sublistView(data, headerSize));
}
