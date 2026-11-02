"""Bản ghi lưu lâu dài (placeholder). Chỉ nhật ký cảnh báo, không lưu ảnh/audio của người dùng."""

from dataclasses import dataclass


@dataclass(frozen=True)
class AlertLog:
    session_id: str
    ts: float
    level: str
    label: str
    direction: str
    distance_m: float | None = None
