Box = tuple[float, float, float, float]  # x1, y1, x2, y2 chuẩn hóa 0..1

LEFT_EDGE = 1 / 3
RIGHT_EDGE = 2 / 3


def direction(box: Box) -> str:
    """'left' | 'ahead' | 'right' theo tâm bbox."""
    cx = (box[0] + box[2]) / 2
    if cx < LEFT_EDGE:
        return "left"
    return "right" if cx > RIGHT_EDGE else "ahead"


def area(box: Box) -> float:
    return max(0.0, box[2] - box[0]) * max(0.0, box[3] - box[1])
