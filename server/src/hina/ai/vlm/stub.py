class StubVLM:
    async def answer(self, image: bytes, question: str | None) -> str:
        return "Phía trước là một con đường có nhiều xe máy."
