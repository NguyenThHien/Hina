import httpx

from hina.ai.base import Detection
from hina.ai.http_api import post_model, scale_box


class PpocrTextDetector:
    """Phát hiện vùng chữ (PP-OCRv5 det) cho READ_TEXT; polygon pixel -> bbox chuẩn hoá."""

    remote = True

    def __init__(self, http: httpx.AsyncClient, base_url: str, api_key: str, timeout_s: float) -> None:
        self._http, self._key, self._timeout = http, api_key, timeout_s
        self._url = f"{base_url.rstrip('/')}/detect"

    async def detect(self, image: bytes) -> list[Detection]:
        res = await post_model(
            self._http, self._url, self._key, timeout=self._timeout,
            files={"file": ("frame.jpg", image, "image/jpeg")},
        )
        data = res.json()
        w, h = data["width"], data["height"]
        out = []
        for b in data["boxes"]:
            xs = [p[0] for p in b["polygon"]]
            ys = [p[1] for p in b["polygon"]]
            out.append(Detection("text", scale_box(min(xs), min(ys), max(xs), max(ys), w, h), b["score"]))
        return out
