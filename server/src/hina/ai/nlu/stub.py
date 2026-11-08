from hina.ai.base import Intent, NluResult

# Thứ tự quan trọng: cụm kết thúc phiên phải khớp trước các từ để hỏi chung chung.
_RULES: tuple[tuple[Intent, tuple[str, ...]], ...] = (
    (Intent.END_SESSION, ("kết thúc", "tạm biệt", "dừng phiên", "thoát")),
    (Intent.READ_TEXT, ("đọc",)),
    (Intent.DESCRIBE_SCENE, ("mô tả", "tả cảnh", "trước mặt", "xung quanh")),
    (Intent.ANSWER_VISUAL_QUESTION, ("?", "gì", "màu", "bao nhiêu", "đâu")),
)


class StubNLU:
    """Rule-based baseline; PhoBERT so sánh với cái này."""

    async def parse(self, text: str) -> NluResult:
        t = text.lower()
        for intent, keywords in _RULES:
            if any(k in t for k in keywords):
                return NluResult(intent)
        return NluResult(Intent.UNKNOWN)
