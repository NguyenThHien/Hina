"""Nhật ký luồng request cho trang /debug (chỉ bật khi HINA_DEBUG=true).

Giữ trong RAM, giới hạn số sự kiện; mỗi session chỉ giữ frame ảnh mới nhất.
"""

import time
from collections import deque

MAX_EVENTS = 500
MAX_TEXT = 300  # cắt chuỗi dài (câu trả lời, base64...) cho gọn


class DebugLog:
    def __init__(self, enabled: bool, max_events: int = MAX_EVENTS) -> None:
        self.enabled = enabled
        self._events: deque[dict] = deque(maxlen=max_events)
        self._seq = 0
        self._frames: dict[str, dict] = {}  # sid -> {count, at, jpeg}

    def add(self, sid: str, rid: int | None, stage: str, **data: object) -> None:
        if not self.enabled:
            return
        self._seq += 1
        clean = {k: (v[:MAX_TEXT] if isinstance(v, str) else v) for k, v in data.items()}
        head = {"seq": self._seq, "t": time.time(), "sid": sid, "rid": rid, "stage": stage}
        self._events.append(head | clean)

    def frame(self, sid: str, jpeg: bytes) -> None:
        if not self.enabled:
            return
        f = self._frames.setdefault(sid, {"count": 0})
        f.update(count=f["count"] + 1, at=time.time(), jpeg=jpeg, bytes=len(jpeg))

    def forget(self, sid: str) -> None:
        self._frames.pop(sid, None)

    def events(self, after: int = 0) -> list[dict]:
        return [e for e in self._events if e["seq"] > after]

    def sessions(self) -> dict[str, dict]:
        return {sid: {k: v for k, v in f.items() if k != "jpeg"} for sid, f in self._frames.items()}

    def latest_frame(self, sid: str) -> bytes | None:
        return self._frames.get(sid, {}).get("jpeg")
