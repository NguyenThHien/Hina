# Hina mobile (Flutter, Android)

Client mỏng: thu audio + ảnh, gửi lên server qua WSS ([docs/protocol.md](../docs/protocol.md)), đọc kết quả và cảnh báo bằng TTS của điện thoại. Không chạy AI trên máy.

> **Trạng thái:** đã `flutter analyze` + `flutter test` (unit/widget) trên Flutter 3.x. Phần cứng thật (camera/mic trên máy) vẫn cần chạy thử trên thiết bị.

## Xử lý kết quả và âm thanh
- Server trả `intent` dạng tên (`READ_TEXT`, `END_SESSION`, …) kèm `intent_id` 1–5; xem [docs/protocol.md](../docs/protocol.md).
- `END_SESSION`: app đọc lời tạm biệt, đóng kết nối, về Trang chủ và **không tự kết nối lại**; nút "Bắt đầu trò chuyện" mở phiên mới.
- `audio/speech_queue.dart` xếp hàng đọc: cảnh báo `danger` ngắt lời và lặp tối đa 3 lần; kết quả mới thay kết quả chưa đọc; thông báo trạng thái giữ tối đa 8 câu.

## Khởi tạo (một lần, cần Flutter SDK)
```
cd mobile
flutter create --platforms=android --org com.hina --project-name hina_mobile .
flutter pub get
flutter analyze
flutter test
```
`flutter create .` chỉ nên sinh thêm `android/`. Nếu nó ghi đè `pubspec.yaml` hoặc `lib/main.dart`, khôi phục lại bản trong repo.

## Cấu hình Android (sau khi có `android/`)
1. `android/app/src/main/AndroidManifest.xml`, trong `<manifest>`:
   ```xml
   <uses-permission android:name="android.permission.INTERNET"/>
   <uses-permission android:name="android.permission.CAMERA"/>
   <uses-permission android:name="android.permission.RECORD_AUDIO"/>
   ```
2. `minSdk` tối thiểu 23 (`record`): `android/app/build.gradle(.kts)` → `minSdk = 23`.
3. Chạy dev với server HTTP thường (chỉ dev, production phải HTTPS/WSS): tạo `android/app/src/main/res/xml/network_security_config.xml`
   ```xml
   <network-security-config>
     <domain-config cleartextTrafficPermitted="true">
       <domain includeSubdomains="false">10.0.2.2</domain>
     </domain-config>
   </network-security-config>
   ```
   và thêm `android:networkSecurityConfig="@xml/network_security_config"` vào thẻ `<application>`. Thiết bị thật trong LAN: thêm IP máy chạy server vào `<domain>`.

## Chạy
Server (thư mục `server/`): `uv run uvicorn hina.main:app --host 0.0.0.0` (cần `HINA_JWT_SECRET` ≥ 32 ký tự).
```
flutter run                                              # emulator -> http://10.0.2.2:8000
flutter run --dart-define=HINA_SERVER=http://192.168.1.10:8000   # thiết bị thật
```
Với stub AI của server: lần đầu đi qua Giới thiệu → Cấp quyền; ở Trang chủ bấm "Bắt đầu trò chuyện" → "Bắt đầu ghi âm", nói, rồi "Dừng ghi âm". Stub ASR trả câu mặc định nên app đọc "Nhà thuốc"; khung ảnh định kỳ làm server gửi cảnh báo "người phía trước".

## Cấu trúc `lib/` (8 khối theo mục 3.1.2 của tài liệu)
| Thư mục | Khối |
|---|---|
| `ui/` | Giao diện theo `docs/mobile-preview.html`: Giới thiệu, Cấp quyền, Trang chủ, Camera, Ghi âm, Cài đặt |
| `prefs/` | Tuỳ chọn người dùng (màu, cỡ chữ, tương phản, giọng hướng dẫn), lưu bằng `shared_preferences` |
| `session/` | Session Controller (state machine, timeout, bỏ phản hồi cũ theo request id) |
| `voice/` | Voice Activation (stub, chưa có wake-word) |
| `audio/` | Audio Capture (PCM16 mono 16 kHz), Audio Playback (TTS cục bộ) |
| `camera/` | Camera Manager |
| `network/` | Network Manager (HTTPS tạo session, WSS, reconnect) + `ServerEvent` |
| `permissions/` | Permission (vòng đời app xử lý trong `app.dart`) |
| `core/` | `protocol.dart`: khung binary khớp server |

Khung TTS binary từ server hiện bị bỏ qua (stub chỉ trả audio giả); app đọc `text` bằng TTS cục bộ.
