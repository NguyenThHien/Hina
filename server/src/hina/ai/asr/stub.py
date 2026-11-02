_DEFAULT_UTTERANCE = "đọc giúp tôi chữ trên tờ giấy"


class StubASR:
    async def transcribe(self, audio: bytes) -> str:
        # Cho phép test/dev gửi thẳng câu chữ dưới dạng "audio" UTF-8.
        return audio.decode("utf-8", errors="ignore").strip() or _DEFAULT_UTTERANCE
