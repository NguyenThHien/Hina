from hina.geometry import Box


class StubDepth:
    async def distance_m(self, image: bytes, box: Box) -> float | None:
        return 1.5
