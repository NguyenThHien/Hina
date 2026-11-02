# Giao thức Mobile ↔ Server

## HTTPS
| Method | Path | Mô tả |
|---|---|---|
| GET | `/health` | `{"status":"ok"}` |
| POST | `/sessions` | `201 {session_id, token, expires_in}`; token = JWT HS256 (`sid`, `exp`) |
| DELETE | `/sessions/{id}` | Cần `Authorization: Bearer <token>` của đúng session; `204` |

## WSS `/ws`
Header `Authorization: Bearer <token>` (không để token trong query string vì lộ vào log). Sai/hết hạn/session đã xóa: đóng code 1008.

### Binary (khung)
`[1 byte kind][4 byte request_id, big-endian][payload]`, tối đa 5 MB.

| kind | Hướng | Payload |
|---|---|---|
| 1 AUDIO | client → server | 1 lượt nói hoàn chỉnh (VAD cắt ở mobile) → chạy ASR→NLU→…→TTS |
| 2 IMAGE | client → server | 1 frame JPEG; luôn đưa vào Safety, và là ảnh dùng cho request kế tiếp |
| 3 TTS | server → client | audio MP3 phản hồi cho `request_id` tương ứng. **Có thể không có** nếu TTS lỗi/quá hạn: khi đó chỉ có `result` dạng chữ |

### Text (JSON)
- client → server: `{"type":"ping"}`
- server → client:
  - `{"type":"pong"}`
  - `{"type":"result","request_id":N,"intent":"READ_TEXT","text":"..."}`
  - `{"type":"alert","level":"danger|warning","label":"person","direction":"left|ahead|right","distance_m":1.5}` (`distance_m` bỏ qua nếu không đủ tin cậy). Mobile tự phát TTS cục bộ.
  - `{"type":"error","request_id"?:N,"message":"..."}`

Intent `NO_IMAGE` trong `result` nghĩa là yêu cầu cần ảnh mà server chưa nhận frame nào.
