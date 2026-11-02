/// Sự kiện từ server (JSON text frame) cộng với trạng thái kết nối.
sealed class ServerEvent {
  const ServerEvent();

  /// null nếu `type` không biết hoặc thiếu/sai kiểu trường.
  static ServerEvent? fromJson(Map<String, dynamic> j) {
    switch (j) {
      case {
        'type': 'result',
        'request_id': int requestId,
        'intent': String intent,
        'text': String text,
      }:
        return ResultEvent(requestId: requestId, intent: intent, text: text);
      case {
        'type': 'alert',
        'level': String level,
        'label': String label,
        'direction': String direction,
      }:
        final d = j['distance_m'];
        return AlertEvent(
          level: level,
          label: label,
          direction: direction,
          distanceM: d is num ? d.toDouble() : null,
        );
      case {'type': 'error', 'message': String message}:
        final id = j['request_id'];
        return ErrorEvent(requestId: id is int ? id : null, message: message);
      case {'type': 'pong'}:
        return const PongEvent();
      default:
        return null;
    }
  }
}

class ConnectedEvent extends ServerEvent {
  const ConnectedEvent();
}

class DisconnectedEvent extends ServerEvent {
  const DisconnectedEvent();
}

class PongEvent extends ServerEvent {
  const PongEvent();
}

class ResultEvent extends ServerEvent {
  const ResultEvent({required this.requestId, required this.intent, required this.text});
  final int requestId;
  final String intent;
  final String text;
}

class ErrorEvent extends ServerEvent {
  const ErrorEvent({this.requestId, required this.message});
  final int? requestId;
  final String message;
}

const _labelsVi = {
  'person': 'người',
  'motorcycle': 'xe máy',
  'car': 'ô tô',
  'bicycle': 'xe đạp',
  'pole': 'cột',
  'pothole': 'ổ gà',
  'stairs': 'cầu thang',
  'bin': 'thùng rác',
  'fence': 'hàng rào',
};
const _directionsVi = {'left': 'bên trái', 'ahead': 'phía trước', 'right': 'bên phải'};

class AlertEvent extends ServerEvent {
  const AlertEvent({
    required this.level,
    required this.label,
    required this.direction,
    this.distanceM,
  });
  final String level; // 'danger' | 'warning'
  final String label;
  final String direction; // 'left' | 'ahead' | 'right'
  final double? distanceM; // null nếu server không đủ tin cậy

  /// Câu đọc cục bộ bằng TTS của điện thoại.
  String get speech {
    final what = _labelsVi[label] ?? label;
    final where = _directionsVi[direction] ?? direction;
    final d = distanceM;
    final dist = d == null ? '' : ', cách khoảng ${d.toStringAsFixed(1)} mét';
    return '${level == 'danger' ? 'Nguy hiểm! ' : 'Cẩn thận, '}$what $where$dist';
  }
}
