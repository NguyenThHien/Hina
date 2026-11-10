"""VLM qua Google Gemini API (REST generateContent), không dùng SDK.

Gọi thẳng, KHÔNG qua GpuScheduler (remote = True): chờ mạng trong scheduler sẽ chặn Safety.
Ảnh môi trường của người dùng được gửi lên Google: ghi rõ trong báo cáo/điều khoản.
"""

import base64

import httpx

SYSTEM_PROMPT = (
    "Bạn là Hina, trợ lý cho người khiếm thị. Trả lời bằng tiếng Việt, 1 đến 2 câu ngắn, "
    "dễ nghe khi đọc thành tiếng, không dùng ký hiệu hay gạch đầu dòng. "
    "Ưu tiên vật quan trọng và vị trí tương đối với người dùng (bên trái, bên phải, phía trước). "
    "Nếu ảnh mờ, tối hoặc không chắc chắn thì nói rõ là không chắc, không bịa. "
    "Không đoán danh tính người trong ảnh."
)
CAPTION_PROMPT = "Mô tả ngắn gọn cảnh trước mặt người dùng."
VQA_PROMPT = "Người dùng hỏi: {question}\nTrả lời câu hỏi dựa trên ảnh."


def _b64(data: bytes) -> str:
    return base64.b64encode(data).decode()


class VlmError(RuntimeError):
    pass


class GeminiVLM:
    remote = True  # Orchestrator gọi thẳng, không qua GpuScheduler

    def __init__(self, http: httpx.AsyncClient, api_key: str, model: str, base_url: str) -> None:
        self._http = http
        self._url = f"{base_url.rstrip('/')}/models/{model}:generateContent"
        self._headers = {"x-goog-api-key": api_key}

    async def answer(self, image: bytes, question: str | None) -> str:
        """question=None: mô tả cảnh (DESCRIBE_SCENE); có question: VQA."""
        q = (question or "").strip()
        prompt = VQA_PROMPT.format(question=q) if q else CAPTION_PROMPT
        body = {
            "systemInstruction": {"parts": [{"text": SYSTEM_PROMPT}]},
            "contents": [
                {
                    "role": "user",
                    "parts": [
                        {"inline_data": {"mime_type": "image/jpeg", "data": _b64(image)}},
                        {"text": prompt},
                    ],
                }
            ],
            "generationConfig": {"temperature": 0.2},
        }
        res = await self._http.post(self._url, json=body, headers=self._headers)
        if res.status_code != 200:
            raise VlmError(f"gemini http {res.status_code}: {_message(res)}")
        return _text(res.json())


def _text(data: object) -> str:
    try:
        parts = data["candidates"][0]["content"]["parts"]  # type: ignore[index]
        text = " ".join(p.get("text", "") for p in parts).strip()
    except (KeyError, IndexError, TypeError):
        reason = data.get("promptFeedback", {}).get("blockReason") if isinstance(data, dict) else None
        raise VlmError(f"gemini returned no answer (block reason: {reason})") from None
    if not text:
        raise VlmError("gemini returned empty text")
    return text


def _message(res: httpx.Response) -> str:
    try:
        return str(res.json()["error"]["message"])[:200]
    except (ValueError, KeyError, TypeError):
        return res.text[:200]
