import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'package:hina_mobile/core/protocol.dart';
import 'package:hina_mobile/network/server_event.dart';

abstract class NetworkManager {
  Stream<ServerEvent> get events;
  bool get isConnected;

  /// Tạo session (HTTPS) rồi mở WSS. Phát [ConnectedEvent] khi sẵn sàng; tự reconnect khi rớt.
  Future<void> connect();
  void sendAudio(int requestId, Uint8List pcm);
  void sendImage(int frameId, Uint8List jpeg);

  /// Đóng phiên hiện tại (server đã đóng WS với mã 1000) và **không** tự kết nối lại.
  Future<void> endSession();
  Future<void> close();
}

class HttpWsNetworkManager implements NetworkManager {
  HttpWsNetworkManager(this.baseUrl, {http.Client? client}) : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;
  final _events = StreamController<ServerEvent>.broadcast();

  WebSocketChannel? _channel;
  String? _sessionId;
  String? _token;
  bool _closed = false;
  bool _ended = false;
  int _attempt = 0;
  Timer? _retry;
  Frame? _tts;

  @override
  Stream<ServerEvent> get events => _events.stream;

  @override
  bool get isConnected => _channel != null;

  @override
  Future<void> connect() {
    _closed = false;
    _ended = false;
    return _open();
  }

  Future<void> _open() async {
    try {
      final res = await _client.post(Uri.parse('$baseUrl/sessions')).timeout(const Duration(seconds: 10));
      if (res.statusCode != 201) throw HttpException('session ${res.statusCode}');
      final body = jsonDecode(res.body);
      if (body case {'session_id': String sessionId, 'token': String token}) {
        _sessionId = sessionId;
        _token = token;
      } else {
        throw const FormatException('bad session response');
      }

      final base = Uri.parse(baseUrl);
      final wsUrl = base.replace(scheme: base.scheme == 'https' ? 'wss' : 'ws', path: '/ws');
      final channel = IOWebSocketChannel.connect(wsUrl, headers: {'Authorization': 'Bearer ${_token ?? ''}'});
      await channel.ready;

      _channel = channel;
      _attempt = 0;
      _events.add(const ConnectedEvent());
      channel.stream.listen(
        _onMessage,
        onDone: _onDown,
        onError: (_) => _onDown(),
        cancelOnError: true,
      );
    } on Exception {
      // mạng/HTTP/timeout/parse: coi như rớt kết nối và thử lại
      _onDown();
    }
  }

  void _onMessage(dynamic message) {
    if (message is List<int>) {
      _onBinary(Uint8List.fromList(message));
      return;
    }
    if (message is! String) return;
    try {
      final json = jsonDecode(message);
      if (json is! Map<String, dynamic>) return;
      var event = ServerEvent.fromJson(json);
      if (event is ResultEvent) {
        final tts = _tts;
        _tts = null;
        if (tts != null && tts.requestId == event.requestId) event = event.withAudio(tts.payload);
      }
      if (event != null) _events.add(event);
    } on Exception {
      // message sai định dạng: bỏ qua, không làm rớt kết nối
    }
  }

  /// Server gửi khung TTS ngay trước result cùng request_id: giữ lại để gắn vào result.
  void _onBinary(Uint8List data) {
    try {
      final frame = decodeFrame(data);
      if (frame.kind == Kind.tts) _tts = frame;
    } on ProtocolException {
      // khung hỏng: bỏ qua, result vẫn được đọc bằng TTS của máy
    }
  }

  void _onDown() {
    _channel = null;
    if (_closed || _ended) return;
    _events.add(const DisconnectedEvent());
    _retry?.cancel();
    final delay = Duration(seconds: min(15, 1 << min(_attempt, 4))); // 1,2,4,8,15s
    _attempt++;
    _retry = Timer(delay, _open);
  }

  @override
  void sendAudio(int requestId, Uint8List pcm) => _channel?.sink.add(encodeFrame(Kind.audio, requestId, pcm));

  @override
  void sendImage(int frameId, Uint8List jpeg) => _channel?.sink.add(encodeFrame(Kind.image, frameId, jpeg));

  @override
  Future<void> endSession() async {
    _ended = true;
    _retry?.cancel();
    _retry = null;
    final channel = _channel;
    _channel = null;
    await channel?.sink.close();
    _sessionId = null;
    _token = null;
  }

  @override
  Future<void> close() async {
    _closed = true;
    _retry?.cancel();
    final channel = _channel;
    _channel = null;
    await channel?.sink.close();
    if (_sessionId != null && _token != null) {
      try {
        await _client.delete(
          Uri.parse('$baseUrl/sessions/$_sessionId'),
          headers: {'Authorization': 'Bearer $_token'},
        ).timeout(const Duration(seconds: 3));
      } on Exception {
        // best-effort: token tự hết hạn
      }
    }
    await _events.close();
  }
}
