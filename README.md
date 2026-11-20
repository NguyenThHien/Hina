# Hina: Trợ lý cho người khiếm thị

Mobile (Flutter) ↔ Server (FastAPI modular monolith, AI chạy phía server).

```
server/      FastAPI: gateway, session, orchestrator, safety, aggregator, ai/ (Protocol + stub)
mobile/      Flutter (Android), đã analyze + test; xem mobile/README.md
benchmarks/  so sánh model ASR/NLU/OCR/Detection
docs/        protocol.md, adr/
```

## Chạy server
```
cd server
uv sync
set HINA_JWT_SECRET=<>=32 ký tự>        # PowerShell: $env:HINA_JWT_SECRET="..."
uv run uvicorn hina.main:app --reload
uv run pytest -q
uv run ruff check .
```
Hoặc `cp .env.example .env`, điền secret, rồi `docker compose up --build`.

Code mặc định mọi khối AI là stub (`HINA_ASR=stub`, …); `.env.example` bật các model tự host bên dưới. Thêm model thật: viết impl theo Protocol trong `server/src/hina/ai/base.py`, đăng ký ở `ai/registry.py`, đổi biến môi trường.

### Bật NLU thật
```
HINA_NLU=http
HINA_NLU_URL=https://nlu.frshdrp.vn
HINA_NLU_TIMEOUT_S=5
```
Server gọi `POST {HINA_NLU_URL}/v1/predict` với `{"text": "<câu ASR>"}` và đọc `label_id` (1–5). Lỗi mạng/timeout/nhãn lạ → `UNKNOWN` (hỏi lại), không làm hỏng phiên.

### Bật model tự host (mặc định trong `.env.example`)
Mỗi model là một API riêng (image `obito05/*-api`, header `X-API-Key`). Điền key vào `server/.env`:

| Khối | `.env` | URL mặc định | Key |
|---|---|---|---|
| ASR | `HINA_ASR=phowhisper` | `https://stt.frshdrp.vn` | `HINA_PHOWHISPER_API_KEY` |
| Vùng chữ (READ_TEXT) | `HINA_TEXT_DETECTOR=ppocr` | `https://ocr-det.frshdrp.vn` | `HINA_PPOCR_API_KEY` |
| OCR | `HINA_OCR=vietocr` | `https://ocr.frshdrp.vn` | `HINA_VIETOCR_API_KEY` |
| Vật cản (Safety) | `HINA_DETECTOR=yolo` | `https://yolo.frshdrp.vn` | `HINA_YOLO_API_KEY` |
| Khoảng cách | `HINA_DEPTH=none` | (chưa có model: dùng diện tích bbox) | |
| VLM | `HINA_VLM=smolvlm` | `https://vlm.frshdrp.vn` | `HINA_SMOLVLM_API_KEY` |
| TTS | `HINA_TTS=mms` | `https://tts.frshdrp.vn` | `HINA_MMS_API_KEY` |

- Thiếu key của model đang bật thì server dừng ngay khi khởi động và báo tên biến.
- Server Hina chạy cùng mạng docker `freshdrip` thì đổi URL thành `http://<container>:8000` (vd `http://vietocr-api:8000`) để khỏi đi vòng qua Cloudflare.
- Các impl này có `remote = True`: gọi thẳng, không xếp hàng `GpuScheduler`, nên chờ mạng không chặn Safety.
- Mobile gửi PCM16 thô; server bọc thành WAV (`preprocess/audio.py`) trước khi gửi PhoWhisper.
- Đổi lại Gemini/FPT: `HINA_VLM=gemini` (+ `HINA_VLM_TIMEOUT_S=15`), `HINA_TTS=fpt`.

**Giới hạn:**
- SmolVLM-256M chỉ trả lời tiếng Anh, có thể không hiểu câu hỏi tiếng Việt; MMS đọc câu tiếng Anh bằng giọng Việt nên khó nghe. Trên CPU mỗi câu ~50 s (`HINA_VLM_TIMEOUT_S=90`); qua domain Cloudflare sẽ bị cắt ở 100 s.
- `HINA_DEPTH=none`: cảnh báo vật cản chỉ dựa trên bbox chiếm ≥ 30% khung hình, không có số mét.
- License: VietOCR fine-tune trên VinText (chỉ nghiên cứu), MMS-TTS (CC-BY-NC 4.0), YOLO11 (AGPL-3.0). Dùng cho đồ án được, không dùng thương mại.

### Bật TTS thật (FPT.AI)
Điền vào `server/.env` (xem `.env.example`):
```
HINA_TTS=fpt
HINA_FPT_API_KEY=<key của bạn>
```
- Bật mà thiếu key thì server dừng ngay khi khởi động và báo tên biến còn thiếu.
- TTS gọi thẳng ra API, không qua hàng đợi GPU, để Safety không bị chặn khi chờ mạng. Timeout: `HINA_TTS_TIMEOUT_S` (20 s).
- TTS lỗi hoặc quá hạn thì app vẫn nhận câu trả lời dạng chữ, chỉ thiếu audio.
- Code: `server/src/hina/ai/tts/fpt.py`.

### Bật VLM Google Gemini
```
HINA_VLM=gemini
HINA_GEMINI_API_KEY=<key từ aistudio.google.com/apikey>
HINA_GEMINI_BASE_URL=https://generativelanguage.googleapis.com/v1beta
HINA_GEMINI_MODEL=gemini-3.5-flash
```
- `DESCRIBE_SCENE` → captioning (mô tả cảnh), `ANSWER_VISUAL_QUESTION` → VQA (câu ASR là câu hỏi).
- Gemini gọi thẳng ra API (không qua hàng đợi GPU), timeout `HINA_VLM_TIMEOUT_S` (15 s). Lỗi/quá hạn → mobile nhận `error` và đọc "Có lỗi, bạn thử lại nhé".
- **Quyền riêng tư:** ảnh camera của người dùng được gửi lên Google. Ghi rõ trong báo cáo.
- Code: `server/src/hina/ai/vlm/gemini.py` (prompt tiếng Việt ở đầu file).

### Trang debug luồng request
Đặt `HINA_DEBUG=true` rồi mở <http://localhost:8000/debug>: mỗi request hiện theo thời gian thực các bước nhận audio → ASR → NLU → OCR/VLM → TTS → gửi MP3/result (kèm thời gian từng bước), cùng frame ảnh mới nhất của từng phiên.
**Chỉ bật khi dev**: trang không có xác thực và hiển thị ảnh/câu nói của người dùng. Mặc định tắt (404).

### VLM tự fine-tune
VLM hiện là stub. Khi có model: viết `server/src/hina/ai/vlm/<tên>.py` có `async def answer(self, image, question) -> str`, chạy inference trong `asyncio.to_thread` (blocking), đăng ký ở `ai/registry.py`, bật bằng `HINA_VLM=<tên>`. VLM đã đi qua hàng đợi GPU, nên Safety vẫn được ưu tiên khi dùng chung GPU.
