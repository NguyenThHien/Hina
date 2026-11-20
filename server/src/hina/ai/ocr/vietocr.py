import httpx

from hina.ai.http_api import post_model


class VietOCR:
    """Đọc chữ trên ảnh một dòng (crop từ text detector)."""

    remote = True

    def __init__(self, http: httpx.AsyncClient, base_url: str, api_key: str, timeout_s: float) -> None:
        self._http, self._key, self._timeout = http, api_key, timeout_s
        self._url = f"{base_url.rstrip('/')}/recognize"

    async def read(self, image: bytes) -> str:
        res = await post_model(
            self._http, self._url, self._key, timeout=self._timeout,
            files={"file": ("crop.jpg", image, "image/jpeg")},
        )
        return str(res.json()["text"]).strip()
