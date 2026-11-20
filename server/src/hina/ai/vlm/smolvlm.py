"""VLM qua smolvlm-api (SmolVLM-256M, CPU). Model chỉ tốt với tiếng Anh: prompt tiếng Anh, trả lời tiếng Anh.

~1 s/token trên CPU: giữ max_new_tokens nhỏ; timeout tổng do Orchestrator (HINA_VLM_TIMEOUT_S).
"""

import httpx

from hina.ai.http_api import post_model

CAPTION_PROMPT = "Describe this image briefly in one sentence."
VQA_PROMPT = "Answer briefly in one sentence: {question}"


class SmolVLM:
    remote = True

    def __init__(self, http: httpx.AsyncClient, base_url: str, api_key: str, max_new_tokens: int) -> None:
        self._http, self._key, self._max_tokens = http, api_key, max_new_tokens
        self._url = f"{base_url.rstrip('/')}/chat"

    async def answer(self, image: bytes, question: str | None) -> str:
        q = (question or "").strip()[:1000]
        prompt = VQA_PROMPT.format(question=q) if q else CAPTION_PROMPT
        res = await post_model(
            self._http, self._url, self._key, timeout=None,  # Orchestrator giới hạn bằng asyncio.timeout
            files={"file": ("frame.jpg", image, "image/jpeg")},
            data={"prompt": prompt, "max_new_tokens": str(self._max_tokens)},
        )
        return str(res.json()["answer"]).strip()
