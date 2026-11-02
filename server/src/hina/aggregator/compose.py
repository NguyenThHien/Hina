from dataclasses import dataclass

from hina.ai.base import Detection
from hina.geometry import direction

NO_IMAGE = "NO_IMAGE"  # intent giả: cần ảnh mà chưa có

_DIRECTION_VI = {"left": "bên trái", "ahead": "phía trước", "right": "bên phải"}
_MESSAGES = {
    NO_IMAGE: "Chưa nhận được hình ảnh, bạn thử lại nhé.",
    "UNKNOWN": "Mình chưa hiểu yêu cầu, bạn nói lại giúp mình.",
}
_EMPTY_READ = "Không đọc được chữ trong ảnh."  # không đoán phần chữ không đọc được
_EMPTY_DETECT = "Không phát hiện vật thể nào trong ảnh."


@dataclass(frozen=True)
class Result:
    intent: str
    text: str = ""
    found: tuple[tuple[Detection, float | None], ...] = ()


def compose(r: Result) -> str:
    if r.intent in _MESSAGES:
        return _MESSAGES[r.intent]
    if r.intent == "READ_TEXT":
        return r.text.strip() or _EMPTY_READ
    if r.intent == "DETECT_OBJECT":
        return ", ".join(_describe(d, dist) for d, dist in r.found) or _EMPTY_DETECT
    return r.text.strip() or _MESSAGES["UNKNOWN"]


def _describe(det: Detection, dist: float | None) -> str:
    s = f"{det.label} {_DIRECTION_VI[direction(det.box)]}"
    return f"{s}, cách khoảng {dist:.1f} mét" if dist is not None else s
