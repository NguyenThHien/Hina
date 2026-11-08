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

Mặc định mọi khối AI là stub (`HINA_ASR=stub`, …). Thêm model thật: viết impl theo Protocol trong `server/src/hina/ai/base.py`, đăng ký ở `ai/registry.py`, đổi biến môi trường.

### Bật NLU thật
```
HINA_NLU=http
HINA_NLU_URL=https://nlu.frshdrp.vn
HINA_NLU_TIMEOUT_S=5
```
Server gọi `POST {HINA_NLU_URL}/v1/predict` với `{"text": "<câu ASR>"}` và đọc `label_id` (1–5). Lỗi mạng/timeout/nhãn lạ → `UNKNOWN` (hỏi lại), không làm hỏng phiên.

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

### VLM tự fine-tune
VLM hiện là stub. Khi có model: viết `server/src/hina/ai/vlm/<tên>.py` có `async def answer(self, image, question) -> str`, chạy inference trong `asyncio.to_thread` (blocking), đăng ký ở `ai/registry.py`, bật bằng `HINA_VLM=<tên>`. VLM đã đi qua hàng đợi GPU, nên Safety vẫn được ưu tiên khi dùng chung GPU.
