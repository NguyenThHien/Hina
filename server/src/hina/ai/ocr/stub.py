class StubOCR:
    async def read(self, image: bytes) -> str:
        return "Nhà thuốc"
