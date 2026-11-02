# ADR 0001: Modular monolith thay vì 13 microservice

**Quyết định:** 13 khối logic chạy trong một process FastAPI; ranh giới giữ bằng package + Protocol (`ai/base.py`). GPU dùng chung qua `GpuScheduler` (Safety ưu tiên hơn request người dùng).

**Lý do:** chỉ có 1 GPU (microservice không thêm tài nguyên); payload ảnh/audio lớn nên mỗi hop nội bộ tốn serialize + latency; nhóm nhỏ, thời gian giới hạn; ưu tiên Safety dễ hơn khi scheduler nằm cùng process.

**Ngoại lệ có thể tách:** OCR (PaddlePaddle) nếu xung đột CUDA/cuDNN với PyTorch.

**Quy tắc phụ thuộc:** `gateway → orchestrator/safety/session`; `orchestrator → ai.base, aggregator`; `safety → ai.base`; `ai/*` không import gateway/orchestrator. Chỉ `main.py` và `ai/registry.py` biết impl cụ thể.

**Điều kiện xem lại:** nhiều GPU/máy, nhiều team deploy độc lập.
