"""Tiền xử lý audio trước ASR (placeholder, chưa nối vào orchestrator)."""


def prepare_audio(audio: bytes) -> bytes:
    # TODO: decode -> mono 16 kHz PCM, chuẩn hóa âm lượng, cắt khoảng lặng đầu/cuối.
    return audio
