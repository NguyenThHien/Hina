/// Địa chỉ server. Emulator Android thấy máy host qua 10.0.2.2.
/// Đổi khi chạy: flutter run --dart-define=HINA_SERVER=https://example.com
const serverUrl = String.fromEnvironment('HINA_SERVER', defaultValue: 'http://10.0.2.2:8000');
