# Hina: Trợ lý cho người khiếm thị

Mobile (Flutter) ↔ Server (FastAPI modular monolith, AI chạy phía server).

```
server/      FastAPI: gateway, session, orchestrator, safety, aggregator, ai/ (Protocol + stub)
mobile/      Flutter (khung viết tay, chưa compile; xem mobile/README.md)
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
