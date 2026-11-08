from dataclasses import dataclass

from hina.ai.base import Intent

NO_IMAGE = "NO_IMAGE"  # intent giả: cần ảnh mà chưa có

_MESSAGES = {
    NO_IMAGE: "Chưa nhận được hình ảnh, bạn thử lại nhé.",
    Intent.UNKNOWN: "Mình chưa hiểu yêu cầu, bạn nói lại giúp mình.",
    Intent.END_SESSION: "Đã kết thúc phiên. Tạm biệt bạn.",
}
_EMPTY_READ = "Không đọc được chữ trong ảnh."  # không đoán phần chữ không đọc được


@dataclass(frozen=True)
class Result:
    intent: Intent | str
    text: str = ""


def compose(r: Result) -> str:
    if r.intent in _MESSAGES:
        return _MESSAGES[r.intent]
    if r.intent is Intent.READ_TEXT:
        return r.text.strip() or _EMPTY_READ
    return r.text.strip() or _MESSAGES[Intent.UNKNOWN]
