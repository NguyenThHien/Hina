from hina.ai.base import Detection
from hina.geometry import area, direction

HAZARD_LABELS = frozenset(
    {"person", "motorcycle", "car", "bicycle", "pole", "pothole", "stairs", "bin", "fence"}
)
DANGER_M = 1.0
WARNING_M = 2.0
# Không có số mét tin cậy: bbox chiếm từng này khung hình thì coi như rất gần.
UNKNOWN_DISTANCE_MIN_AREA = 0.3


def assess(items: list[tuple[Detection, float | None]]) -> dict | None:
    """Chọn vật cản nguy hiểm nhất; None nếu không cần cảnh báo."""
    best: tuple[float, dict] | None = None
    for det, dist in items:
        if det.label not in HAZARD_LABELS:
            continue
        if dist is None:
            if area(det.box) < UNKNOWN_DISTANCE_MIN_AREA:
                continue
            rank, level, extra = WARNING_M, "warning", {}
        elif dist <= WARNING_M:
            rank, level, extra = dist, "danger" if dist <= DANGER_M else "warning", {"distance_m": dist}
        else:
            continue
        alert = {
            "type": "alert",
            "level": level,
            "label": det.label,
            "direction": direction(det.box),
            **extra,
        }
        if best is None or rank < best[0]:
            best = (rank, alert)
    return best[1] if best else None
