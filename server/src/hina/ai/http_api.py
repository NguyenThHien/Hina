"""Gọi các model tự host (FastAPI, header X-API-Key): phowhisper, ppocr-det, vietocr, yolo11, smolvlm, mms.

Mọi impl dùng helper này đều có `remote = True`: Orchestrator/Safety gọi thẳng, không xếp vào
GpuScheduler (chờ mạng trong scheduler tuần tự sẽ chặn Safety).
"""

import httpx


class ModelApiError(RuntimeError):
    pass


async def post_model(
    http: httpx.AsyncClient, url: str, api_key: str, *, timeout: float, **kwargs
) -> httpx.Response:
    """POST tới API model; mã khác 200 -> ModelApiError (không kèm key)."""
    res = await http.post(url, headers={"X-API-Key": api_key}, timeout=timeout, **kwargs)
    if res.status_code != 200:
        raise ModelApiError(f"{url} -> http {res.status_code}: {res.text[:200]}")
    return res


def scale_box(x1: float, y1: float, x2: float, y2: float, width: float, height: float):
    """Box pixel -> chuẩn hoá 0..1 (clamp)."""

    def clamp(v: float) -> float:
        return min(1.0, max(0.0, v))

    return (clamp(x1 / width), clamp(y1 / height), clamp(x2 / width), clamp(y2 / height))
