# Benchmarks

Tách khỏi server. Mỗi nhánh một thư mục khi bắt đầu làm: `asr/`, `nlu/`, `ocr/`, `detection/`.
Dataset để trong `<nhánh>/data/` (đã gitignore). Metric dùng chung ở `common/metrics.py` (CER/WER).

Chạy test metric: `cd benchmarks/common && uv run --project ../../server pytest -q`
