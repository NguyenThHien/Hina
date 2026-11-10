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
| 3 TTS | server → client | audio MP3 phản hồi cho `request_id` tương ứng, gửi **ngay trước** `result` cùng id. **Có thể không có** nếu TTS lỗi/quá hạn: khi đó mobile đọc `text` bằng TTS của máy |

### Text (JSON)
- client → server: `{"type":"ping"}`
- server → client:
  - `{"type":"pong"}`
  - `{"type":"result","request_id":N,"intent":"READ_TEXT","intent_id":1,"text":"..."}`
  - `{"type":"alert","level":"danger|warning","label":"person","direction":"left|ahead|right","distance_m":1.5}` (`distance_m` bỏ qua nếu không đủ tin cậy). Mobile tự phát TTS cục bộ.
  - `{"type":"error","request_id"?:N,"message":"..."}`

### Intent
NLU trả về `label_id` số (1–5); server gửi kèm cả tên và số trong `result`.

| `intent` | `intent_id` | Hành vi |
|---|---|---|
| `READ_TEXT` | 1 | detect → crop từng đối tượng (tối đa 3, confidence ≥ 0.5) → OCR |
| `DESCRIBE_SCENE` | 2 | VLM captioning: mô tả cảnh trong ảnh (không truyền câu hỏi) |
| `ANSWER_VISUAL_QUESTION` | 3 | VLM VQA: trả lời câu hỏi (text ASR) dựa trên ảnh |
| `END_SESSION` | 4 | trả lời tạm biệt rồi **đóng WS với mã 1000**; mobile không tự kết nối lại |
| `UNKNOWN` | 5 | yêu cầu người dùng nói lại |

`intent` = `NO_IMAGE` (không có `intent_id`) nghĩa là yêu cầu cần ảnh mà server chưa nhận frame nào.

Đóng WS: `1008` chỉ dùng cho auth sai/hết hạn/session đã xoá; `1000` là kết thúc phiên bình thường.
