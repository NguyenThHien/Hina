from hina.ai.base import Detection


class StubDetector:
    async def detect(self, image: bytes) -> list[Detection]:
        return [Detection("person", (0.4, 0.3, 0.6, 0.9), 0.9)]
