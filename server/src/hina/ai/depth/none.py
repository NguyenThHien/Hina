from hina.geometry import Box


class NoDepth:
    """Chưa có model depth: trả None để Safety dùng heuristic diện tích bbox (safety/risk.py).

    Không dùng StubDepth (luôn 1.5 m) với detector thật: mọi người trong khung hình sẽ bị báo động.
    """

    remote = True  # không tốn GPU: khỏi xếp hàng scheduler

    async def distance_m(self, image: bytes, box: Box) -> float | None:
        return None
