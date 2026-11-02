from hina.ai.base import Intent, NluResult

_RULES: tuple[tuple[Intent, tuple[str, ...]], ...] = (
    (Intent.READ_TEXT, ("đọc",)),
    (Intent.DETECT_OBJECT, ("vật cản", "chướng ngại", "ở đâu", "phía nào")),
    (Intent.DESCRIBE_SCENE, ("mô tả", "trước mặt", "có gì")),
    (Intent.VISUAL_QUESTION, ("?", "gì", "màu", "bao nhiêu")),
)


class StubNLU:
    """Rule-based baseline; PhoBERT so sánh với cái này."""

    async def parse(self, text: str) -> NluResult:
        t = text.lower()
        for intent, keywords in _RULES:
            if any(k in t for k in keywords):
                return NluResult(intent)
        return NluResult(Intent.UNKNOWN)
