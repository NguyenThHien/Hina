import httpx

from hina.ai.base import Detection
from hina.ai.http_api import post_model, scale_box


class YoloDetector:
    """Phát hiện vật cản (YOLO11, nhãn COCO) cho Safety."""

    remote = True

    def __init__(
        self, http: httpx.AsyncClient, base_url: str, api_key: str, timeout_s: float, conf: float
    ) -> None:
        self._http, self._key, self._timeout, self._conf = http, api_key, timeout_s, conf
        self._url = f"{base_url.rstrip('/')}/detect"

    async def detect(self, image: bytes) -> list[Detection]:
        res = await post_model(
            self._http, self._url, self._key, timeout=self._timeout,
            files={"file": ("frame.jpg", image, "image/jpeg")}, data={"conf": str(self._conf)},
        )
        data = res.json()
        w, h = data["width"], data["height"]
        return [Detection(b["name"], scale_box(*b["box"], w, h), b["confidence"]) for b in data["boxes"]]
