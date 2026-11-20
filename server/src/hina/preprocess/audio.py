"""Tiền xử lý audio trước ASR."""

import io
import wave

SAMPLE_RATE = 16000  # khớp RecordConfig ở mobile/lib/voice/mic_vad.dart


def prepare_audio(audio: bytes) -> bytes:
    """Mobile gửi PCM16 mono 16 kHz thô (không header): bọc thành WAV để ffmpeg phía API đọc được.

    Audio đã có header RIFF/WAV thì để nguyên.
    """
    if audio[:4] == b"RIFF":
        return audio
    buf = io.BytesIO()
    with wave.open(buf, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SAMPLE_RATE)
        w.writeframes(audio[: len(audio) // 2 * 2])  # bỏ byte lẻ cuối nếu có
    return buf.getvalue()
